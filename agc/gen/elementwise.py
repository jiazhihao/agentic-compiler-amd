"""The elementwise template: one map over same-shape 1-D tensors.

Each lane computes `E` consecutive elements (`elements_per_lane`: 1, 2 or 4) with one wide load
per input and one wide store; a workgroup of 256 lanes covers 256 * E elements. Lanes whose `E`
elements do not all exist handle the remaining ones singly under EXEC.
"""
from __future__ import annotations

from ..manifest import Manifest
from ..mir import abi
from ..tair.ir import Program, free_vars
from .binding import Compiled, bind, load_args
from .builder import Builder, GenError
from .expr import ExprCompiler

BLOCK = 256
_LOAD = {1: "global_load_dword", 2: "global_load_dwordx2", 4: "global_load_dwordx4"}
_STORE = {1: "global_store_dword", 2: "global_store_dwordx2", 4: "global_store_dwordx4"}


def matches(p: Program) -> bool:
    ranks = p.ranks()
    return (all(s.reduce is None for s in p.body) and len(p.outputs) == 1
            and all(q.shape is None or len(q.shape) == 1 for q in p.params)
            and ranks[p.outputs[0].name] == "full")


def generate(m: Manifest, p: Program, elements_per_lane: int = 4) -> Compiled:
    E = elements_per_lane
    if E not in (1, 2, 4):
        raise GenError("elements_per_lane must be 1, 2 or 4")
    if not matches(p):
        raise GenError("not an elementwise program (one map over 1-D tensors)")
    bd = bind(m, p)
    out = p.outputs[0]
    out_tensor = bd.outputs[out.name]
    stmts = p.body
    used = {v for s in stmts for v in free_vars(s.expr)}
    tensors = [q.name for q in p.params if q.shape is not None and q.name in used]
    scalars = [q.name for q in p.params if q.shape is None and q.name in used]
    n_name = bd.size_param(next(q.shape[0] for q in p.params if q.shape is not None))
    for t in tensors + [out_tensor]:
        if bd.itemsize(t) not in (2, 4):
            raise GenError(f"{t}: element size {bd.itemsize(t)} is not supported")
    if any(bd.itemsize(t) != 4 for t in tensors):
        raise GenError("inputs must be 32-bit")
    osize = bd.itemsize(out_tensor)

    b = Builder(m.entry)
    ex = ExprCompiler(b)
    A = load_args(b, bd, list(dict.fromkeys(tensors + [out_tensor] + scalars + [n_name])))
    n = A[n_name]
    idx = b.v(2)                                             # element index of the lane's first element (64-bit)
    b.emit("s_lshl_b32", "s2", "s2", 8)                      # workgroup id * 256
    b.emit("v_add_u32_e32", b.part(idx, 0), "s2", "v0")
    if E > 1:
        b.emit("v_lshlrev_b32_e32", b.part(idx, 0), E.bit_length() - 1, b.part(idx, 0))
    b.emit("v_mov_b32_e32", b.part(idx, 1), 0)
    end, tail = b.new_label(), b.new_label()
    whole = b.v()
    b.emit("v_add_u32_e32", whole, E, b.part(idx, 0))
    b.emit("v_cmp_ge_i32_e32", "vcc", n, whole)              # all E elements exist
    save = b.s(2)
    b.emit("s_and_saveexec_b64", save, "vcc")
    b.emit("s_cbranch_execz", tail if E > 1 else end)

    def addresses():
        byte = {}
        for size in sorted({bd.itemsize(t) for t in tensors + [out_tensor]}):
            r = b.v(2)
            b.emit("v_lshlrev_b64", r, size.bit_length() - 1, idx)
            byte[size] = r
        ptr = {}
        for t in dict.fromkeys(tensors + [out_tensor]):
            r = b.v(2)
            b.emit("v_lshl_add_u64", r, A[t], 0, byte[bd.itemsize(t)])
            ptr[t] = r
        return ptr

    def compute(env):
        memo = {}
        for s in stmts:
            env[s.name] = ex.compile(s.expr, env, memo)
        return ex.vec(env[out.name])

    # ---- lanes with all E elements: wide loads, E results, one wide store ----------------------
    ptr = addresses()
    data = {}
    for t in tensors:
        data[t] = b.v(E)
        b.emit(_LOAD[E], data[t], ptr[t], "off")
    results, seqs = [], []
    for e in range(E):
        env = {t: b.part(data[t], e) for t in tensors}
        env.update({s: A[s] for s in scalars})
        start = len(b.blocks[-1].insts)
        results.append(compute(env))
        seqs.append(b.blocks[-1].insts[start:])
        del b.blocks[-1].insts[start:]
    # the E computations are independent: interleave them, so that the wait states a result needs
    # (after a transcendental, for instance) are filled by the other elements' instructions
    for i in range(max(map(len, seqs))):
        b.blocks[-1].insts += [q[i] for q in seqs if i < len(q)]
    if osize == 4:
        packed = b.v(E)
        for e, r in enumerate(results):
            b.emit("v_mov_b32_e32", b.part(packed, e), r)
        b.emit(_STORE[E], ptr[out_tensor], packed, "off")
    else:                                                    # 16-bit results: two per register
        if E == 1:
            b.emit("global_store_short", ptr[out_tensor], results[0], "off")
        else:
            packed = b.v(E // 2)
            for e in range(E // 2):
                b.emit("v_lshl_or_b32", b.part(packed, e), results[2 * e + 1], 16, results[2 * e])
            b.emit(_STORE[E // 2], ptr[out_tensor], packed if E > 2 else b.part(packed, 0), "off")
    # ---- lanes at the end of the array: the elements that exist, one at a time -----------------
    if E > 1:
        b.label(tail)
        b.emit("s_andn2_b64", "exec", save, "exec")          # the lanes that did not take the wide path
        b.emit("s_cbranch_execz", end)
        tptr = addresses()
        cur = b.v()
        for e in range(E - 1):
            b.emit("v_add_u32_e32", cur, e, b.part(idx, 0))
            b.emit("v_cmp_gt_i32_e32", "vcc", n, cur)        # element e exists
            b.emit("s_and_b64", "exec", "exec", "vcc")
            b.emit("s_cbranch_execz", end)
            env = {}
            for t in tensors:
                r = b.v()
                b.emit("global_load_dword", r, tptr[t], "off", **({"offset": 4 * e} if e else {}))
                env[t] = r
            env.update({s: A[s] for s in scalars})
            r = compute(env)
            b.emit("global_store_dword" if osize == 4 else "global_store_short", tptr[out_tensor], r, "off",
                   **({"offset": osize * e} if e else {}))
    b.label(end)
    b.emit("s_endpgm")
    k = b.finish(bd.args)
    return Compiled(abi.make_module([k]), {"grid": [f"cdiv({m.param(n_name).value}, {BLOCK * E})"], "block": [BLOCK], "lds": 0},
                    "elementwise", {"elements_per_lane": E})
