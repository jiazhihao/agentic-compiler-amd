"""Workgroup coarsening: one launched workgroup runs `factor` consecutive workgroups of the original.

The whole kernel body becomes the body of a loop over virtual workgroup ids
`factor * workgroup_id_x + f`, `f = 0 .. factor - 1`. Every virtual workgroup executes exactly the
original instruction sequence on the original entry state (the registers the runtime sets are
saved once and restored per iteration), so the results are bit-identical; what changes is the
launch: `ceil(grid_x / factor)` workgroups, and one more kernel argument that carries the original
`grid_x` (the loop stops there, and a read of `gridDim.x` is redirected to it).

It pays where a wave's fixed costs (launch, argument loads, address setup) are comparable to its
work: the one-element-per-thread kernels of the BLAS and DNN libraries.

Legality:
 - barriers: every path to the end of the program must pass every `s_barrier`, so that all waves
   of a workgroup stay in the same virtual workgroup between barriers;
 - the kernel has no private segment (stack) and no preloaded arguments;
 - a read of the hidden `block_count_x` must be an `s_load_dword` from the kernarg pointer.
"""
from __future__ import annotations

from ..arch.model import Arch, load as load_arch
from .analysis import cfg, entry_defined
from .asm import parse_inst, split_at_branches
from .ir import Block, Imm, Kernel, Reg
from .loops import NotApplicable

HEAD, LATCH, EXIT, BODY = ".Lagc_wg_head", ".Lagc_wg_latch", ".Lagc_wg_exit", ".Lagc_wg_body"
_LOAD_WORDS = {"s_load_dword": 1, "s_load_dwordx2": 2, "s_load_dwordx4": 4, "s_load_dwordx8": 8, "s_load_dwordx16": 16}


def _align(x: int, a: int) -> int:
    return -(-x // a) * a


def _barriers_on_every_path(g, k: Kernel) -> bool:
    exits = {bi for bi, b in enumerate(k.blocks) if any(i.mnemonic == "s_endpgm" for i in b.insts)}
    for bb, b in enumerate(k.blocks):
        if not any(i.mnemonic == "s_barrier" for i in b.insts):
            continue
        if bb == 0:
            continue
        seen, work = {0}, [0]                     # blocks reachable from the entry without entering `bb`
        while work:
            for s in g.succ[work.pop()]:
                if s != bb and s not in seen:
                    seen.add(s)
                    work.append(s)
        if seen & exits:
            return False
    return True


def coarsen(k: Kernel, factor: int, arch: Arch | None = None) -> dict:
    """Rewrite `k` in place. Returns `{"arg_offset": byte offset of the new u32 argument (the original grid_x)}`."""
    arch = arch or load_arch()
    if not isinstance(factor, int) or factor < 2:
        raise NotApplicable("factor must be an integer of at least 2")
    d = k.descriptor
    if any(b.label in (HEAD, LATCH, EXIT, BODY) for b in k.blocks):
        raise NotApplicable("the kernel is already coarsened")
    if not d.get("system_sgpr_workgroup_id_x"):
        raise NotApplicable("the kernel does not receive workgroup_id_x")
    if d.get("enable_private_segment") or d.get("user_sgpr_private_segment_buffer") or d.get("private_segment_fixed_size"):
        raise NotApplicable("the kernel uses a private segment (stack)")
    if d.get("user_sgpr_kernarg_preload_length"):
        raise NotApplicable("the kernel preloads arguments into SGPRs")
    if not d.get("user_sgpr_kernarg_segment_ptr"):
        raise NotApplicable("the kernel has no kernarg segment pointer")
    kptr = 2 * int(bool(d.get("user_sgpr_dispatch_ptr"))) + 2 * int(bool(d.get("user_sgpr_queue_ptr")))
    kreg = Reg("s", kptr, 2)
    wg = d["user_sgpr_count"]
    g = cfg(k, arch=arch)
    if not _barriers_on_every_path(g, k):
        raise NotApplicable("a path reaches the end of the program without passing every s_barrier")
    # ---- the read of gridDim.x ---------------------------------------------------------------------
    hidden_x = next((a[".offset"] for a in k.metadata.get(".args", []) if a.get(".value_kind") == "hidden_block_count_x"), None)
    off = _align(d.get("kernarg_size", 0), 8)
    redirect = []
    if hidden_x is not None:
        # where the kernarg pointer register still holds the pointer: (may, must) at each block entry
        kunits = {("s", kptr), ("s", kptr + 1)}
        n = len(k.blocks)
        kills = [any(i.defs & kunits for i in infos) for infos in g.infos]
        may_in, must_in = [False] * n, [True] * n
        may_in[0] = True
        changed = True
        while changed:
            changed = False
            for bi in range(n):
                if bi:
                    may = any(may_in[p] and not kills[p] for p in g.pred[bi])
                    must = bool(g.pred[bi]) and all(must_in[p] and not kills[p] for p in g.pred[bi])
                    if (may, must) != (may_in[bi], must_in[bi]):
                        may_in[bi], must_in[bi], changed = may, must, True
        for bi, (b, infos) in enumerate(zip(k.blocks, g.infos)):
            may, must = may_in[bi], must_in[bi]
            for x, info in zip(b.insts, infos):
                if may and info.uses & kunits:
                    words = _LOAD_WORDS.get(x.mnemonic)
                    o = x.operands[2] if len(x.operands) > 2 else None
                    if not must:
                        raise NotApplicable(f"`{x}`: may or may not read through the kernarg pointer")
                    if not (info.smem and info.load and words and x.operands[1] == kreg and isinstance(o, Imm)):
                        raise NotApplicable(f"`{x}`: the kernarg pointer is used other than as the base of a scalar load")
                    lo = int(o.value)
                    if lo <= hidden_x < lo + 4 * words:
                        if words != 1:
                            raise NotApplicable(f"`{x}`: gridDim.x is read together with other arguments")
                        redirect.append(x)
                if info.defs & kunits:
                    may = must = False
    # ---- registers ----------------------------------------------------------------------------------
    entry = entry_defined(k)
    written = set().union(*(i.defs for infos in g.infos for i in infos)) if k.blocks else set()
    save_s = sorted(u[1] for u in entry if u[0] == "s" and u in written and u[1] != wg)
    save_v = sorted(u[1] for u in entry if u[0] == "v" and u in written)
    save_exec = ("exec", 0) in written
    top_s = max([wg + 1] + [op.index + op.count for x in k.insts() for op in x.operands
                            if isinstance(op, Reg) and op.cls == "s" and op.index is not None])
    top_v = max([d.get("system_vgpr_workitem_id", 0) + 1] + [op.index + op.count for x in k.insts() for op in x.operands
                                                            if isinstance(op, Reg) and op.cls == "v" and op.index is not None])
    s_next = top_s

    def new_s(n: int = 1) -> int:
        nonlocal s_next
        s_next = _align(s_next, n)
        r, s_next = s_next, s_next + n
        return r
    s_exec = new_s(2) if save_exec else None
    s_cnt, s_base, s_grid = new_s(), new_s(), new_s()
    s_saved = {i: new_s() for i in save_s}
    v_saved = {i: top_v + j for j, i in enumerate(save_v)}
    if s_next > arch.res("max_sgprs"):
        raise NotApplicable(f"needs {s_next} SGPRs, the wave has {arch.res('max_sgprs')}")
    if top_v + len(save_v) > arch.res("max_arch_vgprs"):
        raise NotApplicable("no free VGPR to keep the workitem ids")
    # ---- rewrite --------------------------------------------------------------------------------------
    for x in redirect:
        x.operands[2] = Imm(hex(off))
    I = parse_inst
    pre = [I(f"s_load_dword s{s_grid}, {kreg}, {hex(off)}")]
    if save_exec:
        pre.append(I(f"s_mov_b64 s[{s_exec}:{s_exec + 1}], exec"))
    pre += [I(f"s_mov_b32 s{s_saved[i]}, s{i}") for i in save_s]
    pre += [I(f"v_mov_b32_e32 v{v_saved[i]}, v{i}") for i in save_v]
    if factor & (factor - 1) == 0:
        pre.append(I(f"s_lshl_b32 s{s_base}, s{wg}, {factor.bit_length() - 1}"))
    else:
        pre.append(I(f"s_mul_i32 s{s_base}, s{wg}, {factor}"))
    pre += [I(f"s_mov_b32 s{s_cnt}, 0"), I("s_waitcnt lgkmcnt(0)")]
    head = [I(f"s_add_u32 s{wg}, s{s_base}, s{s_cnt}"), I(f"s_cmp_ge_u32 s{wg}, s{s_grid}"), I(f"s_cbranch_scc1 {EXIT}")]
    if save_exec:
        head.append(I(f"s_mov_b64 exec, s[{s_exec}:{s_exec + 1}]"))
    head += [I(f"s_mov_b32 s{i}, s{s_saved[i]}") for i in save_s]
    head += [I(f"v_mov_b32_e32 v{i}, v{v_saved[i]}") for i in save_v]
    first = k.blocks[0]
    body = [Block(BODY, first.insts, first.align)] + k.blocks[1:]
    for bi, b in enumerate(body):
        for i, x in enumerate(b.insts):
            if x.mnemonic == "s_endpgm":
                b.insts[i] = I(f"s_branch {LATCH}")
        if bi == len(body) - 1 and b.insts and str(b.insts[-1]) == f"s_branch {LATCH}":
            b.insts.pop()                                     # the last block falls through into the latch
    latch = [I(f"s_add_u32 s{s_cnt}, s{s_cnt}, 1"), I(f"s_cmp_lt_u32 s{s_cnt}, {factor}"), I(f"s_cbranch_scc1 {HEAD}")]
    k.blocks = split_at_branches([Block(first.label, pre), Block(HEAD, head)] + body + [Block(LATCH, latch), Block(EXIT, [I("s_endpgm")])])
    # ---- the new argument -----------------------------------------------------------------------------
    k.metadata.setdefault(".args", []).append({".offset": off, ".size": 4, ".value_kind": "by_value"})
    d["kernarg_size"] = off + 8
    k.metadata[".kernarg_segment_size"] = off + 8
    return {"arg_offset": off, "redirected_grid_reads": len(redirect), "saved_sgprs": len(save_s), "saved_vgprs": len(save_v)}
