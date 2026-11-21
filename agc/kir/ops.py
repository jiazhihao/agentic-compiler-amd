"""The operation vocabulary of `kir` and its typing rules.

| Operation | Meaning |
|---|---|
| `tid.x|y|z`, `bid.*`, `bdim.*`, `gdim.*` | `threadIdx`, `blockIdx`, `blockDim`, `gridDim` (u32) |
| `add sub mul div rem and or xor shl shr min max` | two operands of one type; signedness from the type; `div`/`rem` truncate as C. `add[nsw]`, `sub[nsw]`, `mul[nsw]`: the source guarantees no signed overflow |
| `neg not` | one operand (`not` on `i1` is logical) |
| `fma a, b, c` | `a * b + c` rounded once |
| `eq ne lt le gt ge` | compare two operands of one type → `i1`; `ne` on floats is true for NaN |
| `select c, a, b` | `c ? a : b` |
| `cast x` | value conversion to the result type (C rules: truncate, sign- or zero-extend by the source type, int ↔ float) |
| `bitcast x` | same bits, another type of the same size |
| `gep p, i` | `p + i` elements |
| `load p` / `store p, x` | memory |
"""
from __future__ import annotations

from .ir import I1, U32, Const, IRError, Op, Type

BUILTINS = {f"{b}.{d}" for b in ("tid", "bid", "bdim", "gdim") for d in "xyz"}
BINARY = {"add", "sub", "mul", "div", "rem", "and", "or", "xor", "shl", "shr", "min", "max"}
UNARY = {"neg", "not"}
COMPARE = {"eq", "ne", "lt", "le", "gt", "ge"}
INT_ONLY = {"rem", "and", "or", "xor", "shl", "shr", "not"}
COMMUTATIVE = {"add", "mul", "and", "or", "xor", "min", "max", "eq", "ne"}
PURE = BUILTINS | BINARY | UNARY | COMPARE | {"fma", "select", "cast", "bitcast", "gep"}
ALL = PURE | {"load", "store"}


def _same(op: Op, n: int) -> Type:
    if len(op.args) != n:
        raise IRError(f"{op.name} takes {n} operand(s), got {len(op.args)}")
    t = op.args[0].type
    if any(a.type != t for a in op.args):
        raise IRError(f"{op.name}: operands of different types ({', '.join(str(a.type) for a in op.args)})")
    return t


def check(op: Op) -> None:
    """Raise `IRError` unless `op` is well-typed."""
    n, r = op.name, op.result
    rt = r.type if r is not None else None
    if n not in ALL:
        raise IRError(f"unknown operation {n!r}")
    if n == "store":
        if r is not None or len(op.args) != 2 or not op.args[0].type.is_ptr or op.args[0].type.elem != op.args[1].type:
            raise IRError("store takes a pointer and a value of its element type, and has no result")
        return
    if r is None:
        raise IRError(f"{n} has a result")
    if n in BUILTINS:
        want = U32 if not op.args else None
    elif n in BINARY:
        want = _same(op, 2)
        if want.is_ptr or (n in INT_ONLY and not (want.is_int or want.is_bool)) or (want.is_bool and n not in ("and", "or", "xor")):
            raise IRError(f"{n} on {want}")
    elif n in UNARY:
        want = _same(op, 1)
        if (n == "neg" and not (want.is_int or want.is_float)) or (n == "not" and not (want.is_int or want.is_bool)):
            raise IRError(f"{n} on {want}")
    elif n == "fma":
        want = _same(op, 3)
        if not want.is_float:
            raise IRError("fma on a non-float type")
    elif n in COMPARE:
        t = _same(op, 2)
        if t.is_bool and n not in ("eq", "ne"):
            raise IRError(f"{n} on i1")
        want = I1
    elif n == "select":
        if len(op.args) != 3 or not op.args[0].type.is_bool or op.args[1].type != op.args[2].type:
            raise IRError("select takes an i1 and two values of one type")
        want = op.args[1].type
    elif n == "cast":
        if len(op.args) != 1 or op.args[0].type.is_ptr or rt.is_ptr:
            raise IRError("cast converts one non-pointer value")
        want = rt
    elif n == "bitcast":
        if len(op.args) != 1 or op.args[0].type.size != rt.size or rt.is_bool or op.args[0].type.is_bool:
            raise IRError("bitcast needs two types of the same size")
        want = rt
    elif n == "gep":
        if len(op.args) != 2 or not op.args[0].type.is_ptr or not op.args[1].type.is_int:
            raise IRError("gep takes a pointer and an integer")
        want = op.args[0].type
    else:   # load
        if len(op.args) != 1 or not op.args[0].type.is_ptr:
            raise IRError("load takes a pointer")
        want = op.args[0].type.elem
    if want is None or rt != want:
        raise IRError(f"{n}: result is {rt}, expected {want}")
