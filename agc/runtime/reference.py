"""Evaluate the manifest's reference program in NumPy: the oracle of the battery.

`einsum`: accumulated in float64. `python`: `fn(**tensors_and_scalars)` from a file next to the
manifest; inputs arrive in their compute dtype, the result is an array (one output) or a dict.
`none`: the amdclang build of the source is the oracle (differential check).
"""
from __future__ import annotations

import importlib.util
from pathlib import Path

import numpy as np

from ..manifest import Manifest, ManifestError

_MODULES: dict = {}


def _load_function(m: Manifest, magnitude: bool = False):
    """The reference function; with `magnitude`, its `<function>_scale` companion when the file has one."""
    path = (m.path.parent / m.reference.file).resolve()
    key = (str(path), path.stat().st_mtime_ns)
    if key not in _MODULES:
        spec = importlib.util.spec_from_file_location(f"agc_ref_{abs(hash(key))}", path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        _MODULES[key] = mod
    try:
        fn = getattr(_MODULES[key], m.reference.function)
    except AttributeError:
        raise ManifestError(f"reference function {m.reference.function!r} not in {path}") from None
    return getattr(_MODULES[key], m.reference.function + "_scale", fn) if magnitude else fn


def _run(m: Manifest, values: dict[str, np.ndarray], resolved, magnitude: bool = False) -> dict[str, np.ndarray]:
    """Reference on decoded values → decoded outputs by name."""
    ref = m.reference
    if ref.kind == "einsum":
        out = {ref.output: np.einsum(ref.expr, *[values[n].astype(np.float64) for n in ref.inputs], optimize=True)}
    elif ref.kind == "python":
        got = _load_function(m, magnitude)(**values, **resolved.scalars)
        outs = m.outputs()
        out = got if isinstance(got, dict) else {outs[0].name: got}
    elif ref.kind == "tair":
        from ..tair.reference import evaluate as tair_evaluate
        out = tair_evaluate(m, values, resolved)
    else:
        raise ManifestError(f"reference kind {ref.kind!r} cannot be evaluated here")
    missing = [p.name for p in m.outputs() if p.name not in out]
    if missing:
        raise ManifestError(f"reference does not produce output(s) {missing}")
    return out


def evaluate(m: Manifest, inputs: dict[str, np.ndarray], resolved) -> dict[str, np.ndarray]:
    """Storage-typed inputs → storage-typed expected outputs."""
    values = {k: m.param(k).dtype.to_compute(v) for k, v in inputs.items()}
    out = _run(m, values, resolved)
    result = {}
    for p in m.outputs():
        a, want = np.asarray(out[p.name]), resolved.tensors[p.name]
        if a.shape != want:
            if a.size != int(np.prod(want)):
                raise ManifestError(f"reference returns shape {a.shape} for {p.name}; the manifest has {want}")
            a = a.reshape(want)
        with np.errstate(over="ignore", invalid="ignore"):
            result[p.name] = p.dtype.to_storage(a)
    return result


def scale(m: Manifest, inputs: dict[str, np.ndarray], resolved) -> dict[str, np.ndarray] | None:
    """The reference on |inputs| (sum of |terms| for sums and products): the magnitude the `cond`
    tolerance is relative to. None when no output asks for it. A python reference whose terms can
    cancel on |inputs| (`c*y - s*x`) defines `<function>_scale` next to it: called instead, with the
    same arguments, it returns the sum of the magnitudes of the terms."""
    if not m.needs_scale():
        return None
    values = {k: np.abs(m.param(k).dtype.to_compute(v).astype(np.float64)) if m.param(k).dtype.is_float
              else m.param(k).dtype.to_compute(v) for k, v in inputs.items()}
    return {k: np.abs(np.asarray(v, np.float64)) for k, v in _run(m, values, resolved, magnitude=True).items()}
