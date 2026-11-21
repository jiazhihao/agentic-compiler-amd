"""The operation vocabulary of `kir` and its typing rules.

| Operation | Meaning |
|---|---|
| `tid.x|y|z`, `bid.*`, `bdim.*`, `gdim.*` | `threadIdx`, `blockIdx`, `blockDim`, `gridDim` (u32) |
| `add sub mul div rem and or xor shl shr min max` | two operands of one type; signedness from the type; `div`/`rem` truncate as C. `add[nsw]`, `sub[nsw]`, `mul[nsw]`: the source guarantees no signed overflow |
| `neg not` | one operand (`not` on `i1` is logical) |
| `mulhi a, b` | the high 32 bits of the 64-bit product of two 32-bit integers |
| `rcp x` | `1 / x` in floating point, to within one unit in the last place (the machine's reciprocal) |
| `sqrt x`, `abs x`, `rndne x`, `floor x`, `trunc x` | correctly rounded square root, magnitude, round to nearest even, down, toward zero |
| `exp2 x`, `log2 x` | `2^x` and `log2 x` as the machine computes them (about one unit in the last place) |
| `ldexp x, n` | `x * 2^n` (`n` an `i32`); `copysign x, y`: the magnitude of `x` with the sign of `y` |
| `exp x`, `tanh x` | math-library functions: expanded into the operations above by the decision `math.<fn>` (`kir/mathlib.py`) |
| `fma a, b, c` | `a * b + c` rounded once |
| `eq ne lt le gt ge` | compare two operands of one type → `i1`; `ne` on floats is true for NaN |
| `select c, a, b` | `c ? a : b` |
| `cast x` | value conversion to the result type (C rules: truncate, sign- or zero-extend by the source type, int ↔ float) |
| `bitcast x` | same bits, another type of the same size |
| `gep p, i` | `p + i` elements |
| `load p` / `store p, x` | memory |
| `shared[name, bytes]` | the workgroup's shared array `name` (`__shared__`): an `lds<T>` pointer to its first element |
| `barrier` | every thread of the workgroup reaches this point before any continues (`__syncthreads`) |
| `wgreduce[op, size] x` | `x` combined over the `size` threads of the workgroup with `op`, in every thread; the order is that of the DPP lowering (`kir/idioms.py`), not the source's |
"""
from __future__ import annotations

from .ir import I1, U32, Const, IRError, Op, Type

BUILTINS = {f"{b}.{d}" for b in ("tid", "bid", "bdim", "gdim") for d in "xyz"}
BINARY = {"add", "sub", "mul", "div", "rem", "and", "or", "xor", "shl", "shr", "min", "max", "mulhi"}
FLOAT_UNARY = {"rcp", "sqrt", "abs", "rndne", "floor", "trunc", "exp2", "log2", "exp", "tanh"}
LIBRARY = {"exp", "tanh"}                # expanded before lowering
UNARY = {"neg", "not"} | FLOAT_UNARY
COMPARE = {"eq", "ne", "lt", "le", "gt", "ge"}
INT_ONLY = {"rem", "and", "or", "xor", "shl", "shr", "not", "mulhi"}
COMMUTATIVE = {"add", "mul", "and", "or", "xor", "min", "max", "eq", "ne", "mulhi"}
PURE = BUILTINS | BINARY | UNARY | COMPARE | {"fma", "select", "cast", "bitcast", "gep", "shared", "ldexp", "copysign"}
ALL = PURE | {"load", "store", "barrier", "wgreduce"}


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
    if n == "barrier":
        if r is not None or op.args:
            raise IRError("barrier takes no operand and has no result")
        return
    if n == "wgreduce":
        from .idioms import REDUCIBLE
        if len(op.args) != 1 or r is None or r.type != op.args[0].type or op.attrs.get("op") not in REDUCIBLE \
                or not isinstance(op.attrs.get("size"), int) or op.attrs["size"] % 64:
            raise IRError("wgreduce[op, size] combines one value over a workgroup of whole waves")
        return
    if n == "shared":
        if op.args or r is None or not r.type.is_lds or not isinstance(op.attrs.get("bytes"), int) or not op.attrs.get("name"):
            raise IRError("shared[name, bytes] gives an lds<T> pointer")
        return
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
        if (n == "neg" and not (want.is_int or want.is_float)) or (n == "not" and not (want.is_int or want.is_bool)) \
                or (n in FLOAT_UNARY and not want.is_float):
            raise IRError(f"{n} on {want}")
    elif n == "ldexp":
        if len(op.args) != 2 or not op.args[0].type.is_float or str(op.args[1].type) != "i32":
            raise IRError("ldexp takes a float and an i32")
        want = op.args[0].type
    elif n == "copysign":
        want = _same(op, 2)
        if not want.is_float:
            raise IRError("copysign on a non-float type")
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
