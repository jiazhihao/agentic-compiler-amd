"""The operation vocabulary of `wir` and its typing rules.

| Operation | Kind | Meaning |
|---|---|---|
| `arg[offset, size]` | u | a kernel argument, read from the kernarg segment |
| `hidden[field]` | u | a launch parameter the runtime passes (`group_size_x`, `block_count_x`, ...) |
| `wg.x|y|z` | u | the workgroup id |
| `lane.x|y|z` | v | the lane's workitem id within the workgroup |
| the `kir` arithmetic, compares, `select`, `cast`, `bitcast`, `fma` | u if every operand is u and the result kind says so, else v | as in `kir` |
| `ptradd[scale, off] base, index` | u or v | the address `base + index * scale + off` |
| `load[scale, off] base, index` | v | the element at that address, one per lane |
| `store[scale, off] base, index, x` | | |
| `load[scale, off, n]`, `store[.., n]` | v | `n` consecutive elements per lane in one access (a `dwordxN` load): the value is a vector `f32x2` |
| `extract[i] x`, `pack a, b, ..` | v | an element of a vector; a vector from elements |

A `u` result needs `u` operands. A compare gives a `v i1` (a lane mask) or a `u i1` (a condition for
`branch`). `where %mask { }` runs its region for the lanes of the mask; `branch %cond { }` is a
jump on a uniform condition.
"""
from __future__ import annotations

from ..kir import ops as kops
from ..kir.ir import Const, IRError, Op, U32, Value

SOURCES_U = {"arg", "hidden"} | {f"wg.{d}" for d in "xyz"}
SOURCES_V = {f"lane.{d}" for d in "xyz"}
ARITH = (kops.PURE - kops.BUILTINS - {"gep"})
HIDDEN_FIELDS = {f"{n}_{d}" for n in ("block_count", "group_size") for d in "xyz"}
ALL = SOURCES_U | SOURCES_V | ARITH | {"ptradd", "load", "store", "extract", "pack"}


def kind_of(x) -> str:
    return "u" if isinstance(x, Const) else x.kind


def check(op: Op) -> None:
    n, r = op.name, op.result
    if n not in ALL:
        raise IRError(f"unknown wir operation {n!r}")
    kinds = [kind_of(a) for a in op.args]
    if any(k not in ("u", "v") for k in kinds) or (r is not None and r.kind not in ("u", "v")):
        raise IRError(f"{n}: every wir value is `u` or `v`")
    if r is not None and r.kind == "u" and "v" in kinds:
        raise IRError(f"{n}: a uniform result from a per-lane operand")
    if n in SOURCES_U or n in SOURCES_V:
        if op.args or r is None or r.kind != ("u" if n in SOURCES_U else "v"):
            raise IRError(f"{n} takes no operand and gives a `{'u' if n in SOURCES_U else 'v'}` value")
        if n == "hidden" and op.attrs.get("field") not in HIDDEN_FIELDS:
            raise IRError(f"hidden: unknown field {op.attrs.get('field')!r}")
        if n == "arg" and not {"offset", "size"} <= set(op.attrs):
            raise IRError("arg needs `offset` and `size`")
        if n not in ("arg",) and r.type != U32:
            raise IRError(f"{n} is u32")
        return
    if n in ("ptradd", "load", "store"):
        want = 3 if n == "store" else 2
        if len(op.args) != want or not op.args[0].type.is_ptr or not op.args[1].type.is_int or op.args[1].type.bits != 64:
            raise IRError(f"{n} takes a base pointer and a 64-bit index" + (" and a value" if n == "store" else ""))
        if not isinstance(op.attrs.get("scale"), int) or not isinstance(op.attrs.get("off"), int) or op.attrs["scale"] < 1:
            raise IRError(f"{n} needs integer `scale` and `off`")
        elem = op.args[0].type.elem
        count = op.attrs.get("n", 1)
        if count != 1:
            from ..kir.ir import vec
            if n == "ptradd" or not isinstance(count, int) or not 2 <= count <= 4 or elem.size != 4:
                raise IRError(f"{n}: `n` is 2 to 4 elements of 32 bits")
            elem = vec(elem, count)
        if n == "store":
            if r is not None or op.args[2].type != elem:
                raise IRError(f"store: the value is {op.args[2].type}, the pointer's element {elem}")
        elif r is None or r.type != (op.args[0].type if n == "ptradd" else elem):
            raise IRError(f"{n}: wrong result type")
        elif n == "load" and r.kind != "v":
            raise IRError("load gives a per-lane value")
        return
    if n == "extract":
        t = op.args[0].type if len(op.args) == 1 else None
        if t is None or not t.is_vec or not isinstance(op.attrs.get("i"), int) or not 0 <= op.attrs["i"] < t.count or r.type != t.elem:
            raise IRError("extract[i] takes a vector and gives its element i")
        return
    if n == "pack":
        if not 2 <= len(op.args) <= 4 or any(a.type != op.args[0].type for a in op.args) or not r.type.is_vec \
                or r.type.elem != op.args[0].type or r.type.count != len(op.args):
            raise IRError("pack takes 2 to 4 values of one type and gives their vector")
        return
    if any(a.type.is_vec for a in op.args):
        raise IRError(f"{n} on a vector (vectors are only loaded, packed, extracted and stored)")
    kops.check(op)
