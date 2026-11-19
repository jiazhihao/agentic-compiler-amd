"""Generators: tensor programs (`tair`) compiled straight into machine IR by schedule templates.

A template is (`matches(program)`, `generate(manifest, program, **params)`, the parameter space).
The parameters are the knobs an agent or a policy searches over."""
from __future__ import annotations

from ..manifest import Manifest, ManifestError
from ..tair.reference import load_text
from . import elementwise, gemm, rowwise
from .binding import Compiled
from .builder import GenError

TEMPLATES = {
    "elementwise": {"module": elementwise, "doc": "one map over 1-D tensors; each lane computes several consecutive elements",
                    "params": {"elements_per_lane": [1, 2, 4]}, "default": {"elements_per_lane": 4}},
    "rowwise": {"module": rowwise, "doc": "reductions over the last axis and a per-row map; one wave per row, DPP reductions",
                "params": {"unroll": [1, 2, 4]}, "default": {"unroll": 4}},
    "gemm_mfma": {"module": gemm, "doc": "C = A @ B^T on MFMA (bf16 in, f32 out); tiles x tiles 32x32 output tiles per wave",
                  "params": {"tiles": [1, 2, 4], "unroll": [1, 2]}, "default": {"tiles": 4, "unroll": 1}},
}


def program_of(m: Manifest):
    if m.program is None:
        raise GenError(f"manifest {m.name} has no tair `program`")
    try:
        return load_text(m, m.program)
    except ManifestError as e:
        raise GenError(str(e)) from None


def applicable(m: Manifest) -> list[str]:
    p = program_of(m)
    return [n for n, t in TEMPLATES.items() if t["module"].matches(p)]


def generate(m: Manifest, template: str | None = None, params: dict | None = None) -> Compiled:
    p = program_of(m)
    names = applicable(m)
    if template is None:
        if not names:
            raise GenError("no template matches this program")
        template = names[0]
    if template not in TEMPLATES:
        raise GenError(f"no template {template!r} (templates: {', '.join(TEMPLATES)})")
    t = TEMPLATES[template]
    if template not in names:
        raise GenError(f"template {template!r} does not match this program")
    params = {**t["default"], **(params or {})}
    for k, v in params.items():
        if k not in t["params"]:
            raise GenError(f"{template}: unknown parameter {k!r} (parameters: {t['params']})")
        if v not in t["params"][k]:
            raise GenError(f"{template}: {k} must be one of {t['params'][k]}, got {v!r}")
    return t["module"].generate(m, p, **params)


__all__ = ["TEMPLATES", "Compiled", "GenError", "applicable", "generate", "program_of"]
