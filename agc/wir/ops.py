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
| `mulw a, b` | u or v | the 64-bit product of two 32-bit integers |
| `lane.id` | v | the lane's index in the wave |
| `lane.read x, at` | v | `x` of lane `(at >> 2) & 63`, or 0 when that lane is not running (`ds_bpermute_b32`) |
| `lane.reduce[op] x` | v | `x` combined over the 64 lanes of the wave (DPP and `v_readlane`: no memory), in every lane; every lane of the wave must be running |

| `region[name, bytes]` | u | an LDS region of the workgroup: an `lds<T>` handle (lowering assigns its offset; the kernel's LDS size is the sum) |
| `barrier` | | the workgroup's barrier (`s_barrier`); it may not sit under a lane mask a wave could skip |

A load or store whose base is an `lds<T>` handle is an LDS access (`ds_read_*`, `ds_write_*`); its index is a
32-bit integer. A `load` whose base and index are `u` may itself be `u`: one scalar load for the wave (`s_load_dword`),
with `n` up to 16.

A `u` result needs `u` operands. A compare gives a `v i1` (a lane mask) or a `u i1` (a condition for
`branch`). `where %mask { }` runs its region for the lanes of the mask; `branch %cond { }` is a
jump on a uniform condition.
"""
from __future__ import annotations

from ..kir import ops as kops
from ..kir.ir import Const, IRError, Op, U32, Value

SOURCES_U = {"arg", "hidden", "region"} | {f"wg.{d}" for d in "xyz"}
SOURCES_V = {f"lane.{d}" for d in "xyz"} | {"lane.id"}
ARITH = (kops.PURE - kops.BUILTINS - {"gep"})
HIDDEN_FIELDS = {f"{n}_{d}" for n in ("block_count", "group_size") for d in "xyz"}
ALL = SOURCES_U | SOURCES_V | ARITH | {"ptradd", "load", "store", "extract", "pack", "mulw", "barrier", "lane.reduce", "lane.read"}


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
        if n == "region" and not (r.type.is_lds and isinstance(op.attrs.get("bytes"), int) and op.attrs.get("name")):
            raise IRError("region[name, bytes] gives an lds<T> handle")
        if n not in ("arg", "region") and r.type != U32:
            raise IRError(f"{n} is u32")
        return
    if n == "barrier":
        if r is not None or op.args:
            raise IRError("barrier takes no operand and has no result")
        return
    if n in ("ptradd", "load", "store"):
        want = 3 if n == "store" else 2
        bits = 32 if len(op.args) > 1 and op.args[0].type.is_lds else 64
        if len(op.args) != want or not op.args[0].type.is_ptr or not op.args[1].type.is_int or op.args[1].type.bits != bits:
            raise IRError(f"{n} takes a base pointer and a {bits}-bit index" + (" and a value" if n == "store" else ""))
        if op.args[0].type.is_lds and (n == "ptradd" or (r is not None and r.kind != "v")):
            raise IRError(f"an LDS access is per lane, and an LDS address is not a value (`{n}`)")
        if not isinstance(op.attrs.get("scale"), int) or not isinstance(op.attrs.get("off"), int) or op.attrs["scale"] < 1:
            raise IRError(f"{n} needs integer `scale` and `off`")
        elem = op.args[0].type.elem
        count = op.attrs.get("n", 1)
        if count != 1:
            from ..kir.ir import vec
            scalar = n == "load" and r is not None and r.kind == "u"
            if n == "ptradd" or not isinstance(count, int) or elem.size != 4 or \
                    count not in ((2, 4, 8, 16) if scalar else (2, 3, 4)):
                raise IRError(f"{n}: `n` is 2 to 4 elements of 32 bits per lane (2, 4, 8 or 16 for a scalar load)")
            elem = vec(elem, count)
        if n == "store":
            if r is not None or op.args[2].type != elem:
                raise IRError(f"store: the value is {op.args[2].type}, the pointer's element {elem}")
        elif r is None or r.type != (op.args[0].type if n == "ptradd" else elem):
            raise IRError(f"{n}: wrong result type")
        return
    if n == "extract":
        t = op.args[0].type if len(op.args) == 1 else None
        if t is None or not t.is_vec or not isinstance(op.attrs.get("i"), int) or not 0 <= op.attrs["i"] < t.count or r.type != t.elem:
            raise IRError("extract[i] takes a vector and gives its element i")
        return
    if n == "lane.read":
        if len(op.args) != 2 or r is None or r.kind != "v" or r.type != op.args[0].type or r.type.size != 4:
            raise IRError("lane.read x, at: a 32-bit value of another lane")
        return
    if n == "lane.reduce":
        from ..kir.idioms import REDUCIBLE
        if len(op.args) != 1 or r is None or r.kind != "v" or r.type != op.args[0].type or r.type.size != 4 \
                or op.attrs.get("op") not in REDUCIBLE:
            raise IRError("lane.reduce[op] combines one 32-bit value over the wave")
        return
    if n == "mulw":
        ok = len(op.args) == 2 and op.args[0].type == op.args[1].type and op.args[0].type.is_int and op.args[0].type.bits == 32 \
            and r.type.is_int and r.type.bits == 64
        if not ok:
            raise IRError("mulw takes two 32-bit integers of one type and gives a 64-bit integer")
        return
    if n == "pack":
        if not 2 <= len(op.args) <= 4 or any(a.type != op.args[0].type for a in op.args) or not r.type.is_vec \
                or r.type.elem != op.args[0].type or r.type.count != len(op.args):
            raise IRError("pack takes 2 to 4 values of one type and gives their vector")
        return
    if any(a.type.is_vec for a in op.args):
        raise IRError(f"{n} on a vector (vectors are only loaded, packed, extracted and stored)")
    kops.check(op)
