"""The NumPy interpreter of tair: the semantics. Floats are computed in float32 in program order
(`dtype=np.float64` gives the high-precision evaluation used as an oracle)."""
from __future__ import annotations

import ml_dtypes
import numpy as np

from .ir import Call, Const, Expr, Program, TairError, Var


def _eval(e: Expr, env: dict, ft) -> np.ndarray:
    if isinstance(e, Var):
        return env[e.name]
    if isinstance(e, Const):
        return ft(e.value)
    a = [_eval(x, env, ft) for x in e.args]
    with np.errstate(all="ignore"):
        match e.fn:
            case "add": return a[0] + a[1]
            case "sub": return a[0] - a[1]
            case "mul": return a[0] * a[1]
            case "div": return a[0] / a[1]
            case "neg": return -a[0]
            case "abs": return np.abs(a[0])
            case "max": return np.maximum(a[0], a[1])
            case "min": return np.minimum(a[0], a[1])
            case "exp": return np.exp(a[0])
            case "log": return np.log(a[0])
            case "tanh": return np.tanh(a[0])
            case "sqrt": return np.sqrt(a[0])
            case "rsqrt": return ft(1) / np.sqrt(a[0])
            case "rcp": return ft(1) / a[0]
            case "fma": return a[0] * a[1] + a[2]
            case "cast_bf16": return np.asarray(a[0], np.float32).astype(ml_dtypes.bfloat16)
            case "cast_f32": return np.asarray(a[0]).astype(np.float32)
    raise TairError(f"cannot evaluate {e.fn}")


def evaluate(p: Program, args: dict, dtype=np.float32) -> dict[str, np.ndarray]:
    """Outputs by name. Tensor arguments are arrays, scalars are numbers."""
    ft = np.dtype(dtype).type
    env = {}
    for q in p.params:
        if q.name not in args:
            raise TairError(f"missing argument {q.name!r}")
        v = np.asarray(args[q.name])
        env[q.name] = v.astype(dtype) if v.dtype.kind == "f" or q.dtype.startswith(("f", "bf")) else v
    for s in p.body:
        if s.einsum is not None:
            env[s.name] = np.einsum(s.einsum, *[np.asarray(env[a.name]).astype(dtype) for a in s.expr], optimize=True)
            continue
        v = np.asarray(_eval(s.expr, env, ft))
        if s.reduce:
            if v.ndim == 0:
                raise TairError(f"{s.name}: cannot reduce a scalar")
            with np.errstate(all="ignore"):
                v = {"sum": lambda: v.sum(-1, keepdims=True), "max": lambda: v.max(-1, keepdims=True),
                     "min": lambda: v.min(-1, keepdims=True), "mean": lambda: v.mean(-1, keepdims=True),
                     "argmax": lambda: v.argmax(-1)[..., None].astype(np.int32)}[s.reduce]()
        env[s.name] = v
    out = {}
    for o in p.outputs:
        v = env[o.name]
        if o.shape is not None and v.ndim == len(o.shape) + 1 and v.shape[-1] == 1:
            v = v[..., 0]                    # a reduction result declared without its unit axis
        out[o.name] = v
    return out
