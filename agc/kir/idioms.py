"""Idioms in `kir`: structures of the source that have another lowering.

`reductions`: the tree reduction over a workgroup through shared memory,

    red[tid] = mine;  barrier
    for (s = B / 2; s > 0; s >>= 1) { if (tid < s) red[tid] = op(red[tid], red[tid + s]);  barrier }
    r = red[0];  barrier

(with the loop already unrolled, as normalization leaves it). When `op` is one associative and
commutative operation, the decision `reduce.form` may replace the whole structure by
`wgreduce[op, size=B] mine`: the combination of `mine` over the `B` threads of the workgroup,
available in every thread. Its lowering combines the 64 lanes of each wave with DPP and
`v_readlane` (no memory, no barrier) and then the waves through one LDS slot each and one barrier,
instead of log2(B) rounds of LDS traffic and barriers. The order of combination changes, so for
floating-point `add` the result differs in the last bits: the manifest's tolerance is the contract.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from .ir import Const, Func, If, Loop, Op, Value, operands, walk

REDUCIBLE = {"add", "min", "max", "mul", "and", "or", "xor"}
WAVE = 64
ROW = 16                                                   # lanes one DPP row operation reaches


@dataclass
class TreeReduction:
    first: int                   # index of the first statement of the structure in its block
    last: int                    # index of the last one
    op: str
    size: int
    mine: object                 # the operand each thread contributes
    result: Value                # the value every thread reads at the end
    shared: Value


def _def(defs, x):
    return defs.get(id(x)) if isinstance(x, Value) else None


def _slot(defs, p, shared):
    """(index operand or None for slot 0) when `p` is `shared[index]`."""
    if p is shared:
        return (None,)
    d = _def(defs, p)
    if d is not None and d.name == "gep" and d.args[0] is shared:
        return (d.args[1],)
    return None


def _is_tid(defs, x) -> bool:
    """`x` is the thread's x index (possibly converted)."""
    d = _def(defs, x)
    while d is not None and d.name == "cast":
        d = _def(defs, d.args[0])
    return d is not None and d.name == "tid.x"


def _tid_plus(defs, x):
    """c when `x` is tid + c (c a constant), else None."""
    d = _def(defs, x)
    while d is not None and d.name == "cast":
        d = _def(defs, d.args[0])
    if d is not None and d.name == "add" and isinstance(d.args[1], Const) and _is_tid(defs, d.args[0]):
        return int(d.args[1].value)
    return None


def find_reductions(f: Func) -> list[tuple[list, TreeReduction]]:
    """Every tree reduction at the top level of the function (not under a condition or in a loop)."""
    defs = {id(s.result): s for s in f.walk() if isinstance(s, Op) and s.result is not None}
    uses: dict[int, int] = {}
    for s in f.walk():
        for x in operands(s):
            if isinstance(x, Value):
                uses[id(x)] = uses.get(id(x), 0) + 1
    out = []
    body = f.body
    i = 0
    while i < len(body):
        s = body[i]
        r = _match(body, i, defs) if isinstance(s, Op) and s.name == "store" and s.args[0].type.is_lds else None
        if r is not None:
            out.append((body, r))
            i = r.last + 1
        else:
            i += 1
    # the shared array must not be used outside the structure
    keep = []
    for blk, r in out:
        inside = set()
        for st in blk[r.first:r.last + 1]:
            inside.add(id(st))
            if isinstance(st, If):
                inside.update(id(x) for x in walk(st.then))
        geps = [x for x in f.walk() if isinstance(x, Op) and x.name in ("gep", "bitcast") and x.args[0] is r.shared]
        users = [x for x in f.walk() if isinstance(x, Op) and x.name in ("load", "store")
                 and (x.args[0] is r.shared or any(x.args[0] is g.result for g in geps))]
        if all(id(u) in inside for u in users):
            keep.append((blk, r))
    return keep


def _match(body: list, i: int, defs: dict) -> TreeReduction | None:
    first = body[i]
    d = _def(defs, first.args[0])
    if d is None or d.name != "gep" or not _is_tid(defs, d.args[1]):
        return None
    shared, mine = d.args[0], first.args[1]
    sd = _def(defs, shared)
    if sd is None or sd.name != "shared":
        return None
    j = i + 1
    if j >= len(body) or not (isinstance(body[j], Op) and body[j].name == "barrier"):
        return None
    j += 1
    op, steps = None, []

    def skip(k: int) -> int:
        """Past the operations without side effects (the next condition, address arithmetic)."""
        while k < len(body) and isinstance(body[k], Op) and body[k].name not in ("load", "store", "barrier", "wgreduce"):
            k += 1
        return k

    while True:
        k = skip(j)
        if k >= len(body) or not isinstance(body[k], If):
            break
        st = body[k]
        c = _def(defs, st.cond)
        if st.orelse or st.merges or c is None or c.name != "lt" or not _is_tid(defs, c.args[0]) or not isinstance(c.args[1], Const):
            break
        half = int(c.args[1].value)
        ops = [x for x in st.then if isinstance(x, Op)]
        if len(ops) != len(st.then):
            break
        loads = [x for x in ops if x.name == "load"]
        stores = [x for x in ops if x.name == "store"]
        if len(loads) != 2 or len(stores) != 1:
            break
        comb = _def(defs, stores[0].args[1])
        own = [x for x in loads if (s0 := _slot(defs, x.args[0], shared)) and s0[0] is not None and _is_tid(defs, s0[0])]
        far = [x for x in loads if (s0 := _slot(defs, x.args[0], shared)) and s0[0] is not None and _tid_plus(defs, s0[0]) == half]
        if comb is None or not any(comb is x for x in ops) or len(own) != 1 or len(far) != 1 or comb.name not in REDUCIBLE \
                or {id(a) for a in comb.args} != {id(own[0].result), id(far[0].result)}:
            break
        ss = _slot(defs, stores[0].args[0], shared)
        if not ss or ss[0] is None or not _is_tid(defs, ss[0]) or (op is not None and comb.name != op):
            break
        after = skip(k + 1)
        if after >= len(body) or not (isinstance(body[after], Op) and body[after].name == "barrier"):
            break
        op = comb.name
        steps.append(half)
        j = after + 1
    j = skip(j)
    if not steps or steps != [steps[0] >> k for k in range(len(steps))] or steps[-1] != 1 or steps[0] & (steps[0] - 1):
        return None
    if j >= len(body) or not (isinstance(body[j], Op) and body[j].name == "load" and body[j].args[0] is shared):
        return None
    result = body[j].result
    last = j
    if j + 1 < len(body) and isinstance(body[j + 1], Op) and body[j + 1].name == "barrier":
        last = j + 1
    return TreeReduction(i, last, op, 2 * steps[0], mine, result, shared)


def reductions(f: Func, plan) -> Func:
    """Apply the decision `reduce.form` to every tree reduction of `f`."""
    found = find_reductions(f)
    for n, (blk, r) in enumerate(sorted(found, key=lambda x: -x[1].first)):      # from the last one: indices stay valid
        site = f"reduce{len(found) - 1 - n}"
        dpp_ok = r.size % WAVE == 0 and r.result.type.size == 4
        if plan.choose(site, "reduce.form", ["lds_tree", "dpp"] if dpp_ok else ["lds_tree"]) != "dpp":
            continue
        blk[r.first:r.last + 1] = [Op("wgreduce", [r.mine], r.result, {"op": r.op, "size": r.size}, site)]
    from .passes import simplify
    return simplify(f)


def wave_reduce(x: np.ndarray, op: str) -> np.ndarray:
    """The combination of each wave's 64 lanes, in the order the DPP lowering combines them: pairs, quads,
    halves of a row and rows of 16 as a balanced tree, then the four rows in sequence. `x` is [waves, 64]."""
    f = {"add": np.add, "min": np.minimum, "max": np.maximum, "mul": np.multiply, "and": np.bitwise_and,
         "or": np.bitwise_or, "xor": np.bitwise_xor}[op]
    if x.dtype.kind == "f" and op in ("min", "max"):
        f = np.fmin if op == "min" else np.fmax
    cur = x.reshape(x.shape[0], WAVE // ROW, ROW)
    with np.errstate(all="ignore"):
        lane = np.arange(ROW)
        for perm in (lane ^ 1, lane ^ 2, (lane & 8) | (7 - (lane & 7)), 15 - lane):
            cur = f(cur, cur[:, :, perm]).astype(x.dtype)
        rows = cur[:, :, 0]
        res = rows[:, 0]
        for k in range(1, WAVE // ROW):
            res = f(rows[:, k], res).astype(x.dtype)
    return res


def workgroup_reduce(x: np.ndarray, op: str, size: int) -> np.ndarray:
    """`wgreduce`: per wave as `wave_reduce`, then the waves of each workgroup in order. `x` holds whole
    workgroups of `size` threads; the result has one value per thread."""
    f = {"add": np.add, "min": np.minimum, "max": np.maximum, "mul": np.multiply, "and": np.bitwise_and,
         "or": np.bitwise_or, "xor": np.bitwise_xor}[op]
    if x.dtype.kind == "f" and op in ("min", "max"):
        f = np.fmin if op == "min" else np.fmax
    waves = wave_reduce(x.reshape(-1, WAVE), op).reshape(-1, size // WAVE)
    with np.errstate(all="ignore"):
        res = waves[:, 0]
        for k in range(1, size // WAVE):
            res = f(res, waves[:, k]).astype(x.dtype)
    return np.repeat(res, size)
