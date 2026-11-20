"""Counted loops in imported code and the `unroll_loads` pass.

What the agent sessions measured (M5): amdclang issues one load per loop iteration and waits for
it, so such a loop runs at memory latency. `unroll_loads` makes N iterations' loads before one
wait: it recognizes a single-block counted loop whose body is loads from induction pointers
followed by vector arithmetic, and builds

    PRE:   if count < N goto TAIL
    LOOP:  N iterations' loads (wide or with offsets); pointers += N steps; count -= N;
           the arithmetic of the N iterations, in the original order; while count >= N
    TAIL:  if count == 0 goto EXIT
    <the original loop, for the remaining iterations>
    EXIT:

The floating-point operations run in the original order on the same values, so the result is
bit-identical. Waits and hazard wait states are re-derived by `fix_waits` / `fix_hazards`.
"""
from __future__ import annotations

import copy
from dataclasses import dataclass, field

from ..arch.model import Arch, load as load_arch
from . import abi, passes
from .analysis import Cfg, Info, cfg, liveness, units
from .ir import Block, Imm, Inst, Kernel, Label, Reg

_WIDE_V = {4: "global_load_dwordx4", 2: "global_load_dwordx2"}


class NotApplicable(ValueError):
    pass


def refuse_indexed(k: Kernel) -> None:
    """Between `s_set_gpr_idx_on` and `s_set_gpr_idx_off` a vector register operand names the register
    `index + M0`: the register analyses do not model that, so no transform touches such a kernel."""
    if any(x.mnemonic.startswith("s_set_gpr_idx") for x in k.insts()):
        raise NotApplicable("the kernel uses indexed vector registers (s_set_gpr_idx_on)")


@dataclass
class Pointer:
    reg: Reg                       # the register pair holding the address
    step: object                   # int (bytes per iteration) or a loop-invariant SGPR pair
    update: list[int]              # indices of the instructions that advance it
    vector: bool


@dataclass
class Loop:
    block: int
    label: str
    exit_label: str
    counter: Reg
    counter_insts: list[int]       # decrement, compare
    pointers: list[Pointer]
    loads: list[tuple[int, Pointer | None, int]]     # (index, pointer, steps already applied when it executes)
    compute: list[int]
    waits: list[int]
    trip_step: int = 1
    info: dict = field(default_factory=dict)


def _imm(op) -> int | None:
    return int(op.value) if isinstance(op, Imm) and not op.is_float else None


def find_loops(k: Kernel, g: Cfg | None = None, arch: Arch | None = None) -> list[Loop]:
    """The loops `unroll_loads` can transform (others are skipped silently; `explain` says why)."""
    out = []
    for bi in range(len(k.blocks)):
        try:
            out.append(analyze(k, bi, g or cfg(k, arch=arch)))
        except NotApplicable:
            pass
    return out


def explain(k: Kernel, arch: Arch | None = None) -> dict[str, str]:
    """For every single-block loop: 'ok' or the reason it cannot be unrolled."""
    g = cfg(k, arch=arch)
    res = {}
    for bi, b in enumerate(k.blocks):
        if bi in g.succ[bi]:
            try:
                analyze(k, bi, g)
                res[b.label] = "ok"
            except NotApplicable as e:
                res[b.label] = str(e)
    return res


def analyze(k: Kernel, bi: int, g: Cfg) -> Loop:
    b = k.blocks[bi]
    infos = g.infos[bi]
    if bi not in g.succ[bi]:
        raise NotApplicable("not a single-block loop")
    if bi + 1 >= len(k.blocks):
        raise NotApplicable("the loop has no fall-through exit")
    last = b.insts[-1]
    if last.mnemonic != "s_cbranch_scc0" or str(last.operands[0]) != b.label:
        raise NotApplicable("the back edge is not `s_cbranch_scc0` on a counter compare")
    if any(i.branch for i in infos[:-1]):
        raise NotApplicable("the loop body branches")
    # ---- the counter: `s_add_i32 c, c, -1` ... `s_cmp_eq_u32 c, 0` ------------------------------
    cmp_i = next((i for i in range(len(b.insts) - 2, -1, -1) if b.insts[i].mnemonic.startswith("s_cmp")), None)
    if cmp_i is None or b.insts[cmp_i].mnemonic != "s_cmp_eq_u32" or _imm(b.insts[cmp_i].operands[1]) != 0:
        raise NotApplicable("the exit test is not `s_cmp_eq_u32 counter, 0`")
    counter = b.insts[cmp_i].operands[0]
    dec_i = next((i for i, x in enumerate(b.insts) if x.mnemonic in ("s_add_i32", "s_add_u32") and x.operands[0] == counter
                  and x.operands[1] == counter and _imm(x.operands[2]) == -1), None)
    if dec_i is None or dec_i > cmp_i:
        raise NotApplicable("the counter is not decremented by one before the test")
    if any(("scc", 0) in infos[i].defs for i in range(cmp_i + 1, len(b.insts) - 1)):
        raise NotApplicable("the condition code is overwritten between the test and the branch")
    # ---- pointers ---------------------------------------------------------------------------------
    pointers: list[Pointer] = []
    used = {dec_i, cmp_i, len(b.insts) - 1}
    written = set()
    for i in infos:
        written |= i.defs
    for i, x in enumerate(b.insts):
        if i in used:
            continue
        ops = x.operands
        if x.mnemonic == "v_lshl_add_u64" and ops[0] == ops[1] and _imm(ops[2]) == 0:
            step = _imm(ops[3])
            if step is None:
                if not (isinstance(ops[3], Reg) and ops[3].cls == "s" and not set(units(ops[3])) & written):
                    raise NotApplicable(f"`{x}`: the stride is not a loop-invariant scalar")
                step = ops[3]
            pointers.append(Pointer(ops[0], step, [i], True))
            used.add(i)
        elif (x.mnemonic == "s_add_u32" and ops[0] == ops[1] and _imm(ops[2]) is not None and i + 1 < len(b.insts)
              and b.insts[i + 1].mnemonic == "s_addc_u32" and _imm(b.insts[i + 1].operands[2]) == 0
              and b.insts[i + 1].operands[0] == b.insts[i + 1].operands[1] == Reg("s", ops[0].index + 1)):
            pointers.append(Pointer(Reg("s", ops[0].index, 2), _imm(ops[2]), [i, i + 1], False))
            used |= {i, i + 1}
    by_units = {u: p for p in pointers for u in units(p.reg)}
    # ---- loads, waits, arithmetic -----------------------------------------------------------------
    loads, compute, waits = [], [], []
    applied = {id(p): 0 for p in pointers}
    load_dsts: set = set()
    for i, (x, info) in enumerate(zip(b.insts, infos)):
        for p in pointers:
            if i == p.update[-1]:
                applied[id(p)] = 1
        if i in used:
            continue
        if info.name == "s_waitcnt":
            waits.append(i)
        elif info.load and (info.vmem or info.smem) and not info.lds_dma:
            if len(x.operands) < 2:                  # s_memtime, s_memrealtime: a pending result, no address
                raise NotApplicable(f"`{x}`: an asynchronous result without an address")
            addr = x.operands[1]
            if not isinstance(addr, Reg):
                raise NotApplicable(f"`{x}`: unsupported address")
            p = by_units.get(units(addr)[0])
            if p is not None and addr.plain() != p.reg:
                raise NotApplicable(f"`{x}`: the address overlaps a pointer partially")
            if p is None and set(units(addr)) & written:
                raise NotApplicable(f"`{x}`: the address changes in the loop but is not a recognized pointer")
            if info.smem and (len(x.operands) < 3 or _imm(x.operands[2]) is None):
                raise NotApplicable(f"`{x}`: scalar load with a register offset")
            if info.vmem and not (isinstance(x.operands[2], Reg) and x.operands[2].cls == "off"):
                raise NotApplicable(f"`{x}`: vector load with a scalar base")
            if info.defs & load_dsts:                # each copy maps a register to one loaded value
                raise NotApplicable(f"`{x}` loads into a register another load of the loop already wrote")
            loads.append((i, p, applied[id(p)] if p else 0))
            load_dsts |= info.defs
        elif info.valu and not info.mfma and not info.lds_dma:
            control = set(by_units) | set(units(counter))
            if info.defs & {("scc", 0), ("exec", 0)} or info.defs & control:
                raise NotApplicable(f"`{x}` writes loop control state")
            if info.uses & control:                  # the unrolled body advances these once, for all copies
                raise NotApplicable(f"`{x}` reads the counter or a pointer")
            compute.append(i)
        else:
            raise NotApplicable(f"`{x}` is neither a load, a pointer update, the counter nor vector arithmetic")
    if not loads:
        raise NotApplicable("the loop has no loads")
    if not compute:
        raise NotApplicable("the loop has no arithmetic")
    for i in compute:                        # arithmetic may not feed a later load or pointer
        if infos[i].defs & set().union(*(infos[j].uses for j, _, _ in loads)):
            raise NotApplicable(f"`{b.insts[i]}` feeds a load address")
    live = liveness(g, masked_defs_kill=True)
    exit_live = set()
    nxt = g.infos[bi + 1]
    live_in_exit = set(live[bi + 1][0]) if nxt else set()
    if nxt:
        live_in_exit = (live_in_exit - nxt[0].defs) | nxt[0].uses
    if load_dsts & live_in_exit:
        raise NotApplicable("a loaded value is used after the loop")
    return Loop(bi, b.label, k.blocks[bi + 1].label, counter, [dec_i, cmp_i], pointers, loads, compute, waits)


def _fresh(k: Kernel, arch: Arch):
    use = abi.register_use(k)
    nxt = {"v": use["v"], "s": use["s"]}

    def alloc(cls: str, n: int) -> Reg:
        align = 1 if n == 1 else (arch.res("vgpr_tuple_align") if cls == "v" else min(n, arch.res("sgpr_tuple_align_max")))
        base = -(-nxt[cls] // align) * align
        nxt[cls] = base + n
        limit = arch.res("max_arch_vgprs") if cls == "v" else arch.res("max_sgprs")
        if nxt[cls] > limit:
            raise NotApplicable(f"out of {cls} registers")
        return Reg(cls, base, n)
    return alloc


def _rename(inst: Inst, mapping: dict) -> Inst:
    """`inst` with every operand that lies inside a loaded register replaced by the same slice of
    this copy's register (`mapping`: original destination -> new register). A loaded tuple may be
    consumed whole or element by element."""
    unit_map = {}
    for old, new in mapping.items():
        for i in range(old.count):
            unit_map[(old.cls, old.index + i)] = (new.cls, new.index + i)
    new_inst = inst.copy()
    ops = []
    for o in inst.operands:
        if isinstance(o, Reg) and not o.special:
            us = [(o.cls, o.index + i) for i in range(o.count)]
            hit = [u in unit_map for u in us]
            if any(hit):
                tgt = [unit_map.get(u) for u in us]
                if not all(hit) or any(t[0] != tgt[0][0] or t[1] != tgt[0][1] + n for n, t in enumerate(tgt)):
                    raise NotApplicable(f"`{inst}` uses {o}, which straddles a loaded register")
                o = Reg(tgt[0][0], tgt[0][1], o.count, o.neg, o.abs)
        ops.append(o)
    new_inst.operands = ops
    return new_inst


def unroll_loads(k: Kernel, factor: int = 4, loop: str | None = None, wide: bool = True, arch: Arch | None = None) -> dict:
    """Transform one loop of `k` in place (the first applicable one, or the one labelled `loop`).
    Returns what was done. Raises NotApplicable with the reason otherwise."""
    arch = arch or load_arch()
    N = factor
    if N not in (2, 4, 8, 16):
        raise NotApplicable("factor must be 2, 4, 8 or 16")
    refuse_indexed(k)
    g = cfg(k, arch=arch)
    if loop is not None:
        idx = next((i for i, b in enumerate(k.blocks) if b.label == loop), None)
        if idx is None:
            raise NotApplicable(f"no block {loop!r}")
        L = analyze(k, idx, g)
    else:
        reasons = explain(k, arch)
        cands = find_loops(k, g, arch)
        if not cands:
            raise NotApplicable("no loop can be unrolled: " + ("; ".join(f"{a}: {r}" for a, r in reasons.items()) or "the kernel has no single-block loop"))
        L = cands[0]
    b = k.blocks[L.block]
    infos = g.infos[L.block]
    alloc = _fresh(k, arch)
    pre, body = [], []
    names = set(bl.label for bl in k.blocks)

    def label(stem: str) -> str:
        n = 0
        while f".L{stem}{n}" in names:
            n += 1
        names.add(f".L{stem}{n}")
        return f".L{stem}{n}"
    l_loop, l_tail = label("unroll"), label("tail")
    # ---- loads of N iterations ------------------------------------------------------------------
    copies: list[dict] = [dict() for _ in range(N)]          # original destination -> this copy's register
    widened = 0
    strided = [p for p in L.pointers if not isinstance(p.step, int)]
    const_ptrs = [p for p in L.pointers if isinstance(p.step, int)]
    for li, p, delta in L.loads:
        x = b.insts[li]
        dst = x.operands[0]
        if p is not None and not isinstance(p.step, int):
            continue                                            # strided streams are emitted below
        step = p.step if p is not None else 0
        base_off = int(x.mod("offset", "0"), 0) if infos[li].vmem else _imm(x.operands[2])
        size = dst.count * 4
        is_dword = x.mnemonic in ("global_load_dword", "s_load_dword")
        group = 1
        if wide and p is not None and is_dword and step == 4:
            group = min(N, 4) if infos[li].vmem else N         # dwordx4 vector loads; scalar loads up to x16
        for u0 in range(0, N, group):
            off = base_off + (u0 + delta) * step
            if infos[li].vmem:
                if not -4096 <= off <= 4095 - size * (group - 1):
                    raise NotApplicable(f"`{x}`: offset {off} of copy {u0} does not fit the load's 13-bit offset")
                if group == 1:
                    new = alloc("v", dst.count)
                    inst = Inst(x.mnemonic, [new, x.operands[1], x.operands[2]], [(n, v) for n, v in x.mods if n != "offset"])
                    copies[u0][dst.plain()] = new
                else:
                    new = alloc("v", group)
                    inst = Inst(_WIDE_V[group], [new, x.operands[1], x.operands[2]], [(n, v) for n, v in x.mods if n != "offset"])
                    for j in range(group):
                        copies[u0 + j][dst.plain()] = Reg("v", new.index + j)
                    widened += 1
                if off:
                    inst.mods.append(("offset", str(off)))
            else:
                if group == 1:
                    new = alloc("s", dst.count)
                    inst = Inst(x.mnemonic, [new, x.operands[1], Imm(hex(off))])
                    copies[u0][dst.plain()] = new
                else:
                    new = alloc("s", group)
                    inst = Inst(f"s_load_dwordx{group}", [new, x.operands[1], Imm(hex(off))])
                    for j in range(group):
                        copies[u0 + j][dst.plain()] = Reg("s", new.index + j)
                    widened += 1
            body.append(inst)
    for p in strided:                                           # load, advance, load, advance, ...
        mine = [(li, d) for li, q, d in L.loads if q is p]
        for u in range(N):
            for li, d in mine:
                if d == 0:
                    x = b.insts[li]
                    new = alloc("v", x.operands[0].count)
                    copies[u][x.operands[0].plain()] = new
                    body.append(Inst(x.mnemonic, [new, *x.operands[1:]], list(x.mods)))
            body.append(b.insts[p.update[0]].copy())
            for li, d in mine:
                if d == 1:
                    x = b.insts[li]
                    new = alloc("v", x.operands[0].count)
                    copies[u][x.operands[0].plain()] = new
                    body.append(Inst(x.mnemonic, [new, *x.operands[1:]], list(x.mods)))
    # ---- pointers and the counter advance by N iterations ---------------------------------------
    for p in const_ptrs:
        total = p.step * N
        if p.vector:
            if 0 <= total <= 64:
                amount = Imm(str(total))
            else:
                amount = alloc("s", 2)
                pre.append(Inst("s_mov_b64", [amount, Imm(hex(total))]))
            body.append(Inst("v_lshl_add_u64", [p.reg, p.reg, Imm("0"), amount]))
        else:
            lo, hi = Reg("s", p.reg.index), Reg("s", p.reg.index + 1)
            body.append(Inst("s_add_u32", [lo, lo, Imm(str(total) if total <= 64 else hex(total))]))
            body.append(Inst("s_addc_u32", [hi, hi, Imm("0")]))
    body.append(Inst("s_add_i32", [L.counter, L.counter, Imm(str(-N))]))
    body.append(Inst("s_cmp_lt_i32", [L.counter, Imm(str(N))]))
    # ---- the arithmetic of the N iterations, in order -------------------------------------------
    for u in range(N):
        for ci in L.compute:
            body.append(_rename(b.insts[ci], copies[u]))
    body.append(Inst("s_cbranch_scc0", [Label(l_loop)]))
    pre += [Inst("s_cmp_lt_i32", [L.counter, Imm(str(N))]), Inst("s_cbranch_scc1", [Label(l_tail)])]
    tail = [Inst("s_cmp_eq_u32", [L.counter, Imm("0")]), Inst("s_cbranch_scc1", [Label(L.exit_label)])]
    pre_label = label("pre")
    new_blocks = [Block(pre_label, pre), Block(l_loop, body, align=b.align), Block(l_tail, tail)]
    k.blocks[L.block:L.block] = new_blocks
    passes.legalize(k, arch)
    abi.sync_resources(k, arch)
    return {"loop": L.label, "factor": N, "loads_per_wait": len(L.loads) * N if not widened else None,
            "wide_loads": widened, "streams": len(L.pointers), "arithmetic_per_iteration": len(L.compute),
            "bit_identical": True}
