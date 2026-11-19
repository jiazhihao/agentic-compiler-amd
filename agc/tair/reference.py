"""A tair program as a manifest's reference (`"reference": {"kind": "tair", "file" | "text"}`)
or as its high-level input (`"program": {"file" | "text"}`)."""
from __future__ import annotations

import numpy as np

from ..manifest import Manifest, ManifestError
from .interp import evaluate as _evaluate
from .ir import Program, TairError
from .text import parse

_CACHE: dict = {}


def load_text(m: Manifest, spec) -> Program:
    text = spec.text if getattr(spec, "text", None) else None
    if text is None:
        path = (m.path.parent / spec.file).resolve()
        try:
            text = path.read_text()
        except OSError as e:
            raise ManifestError(f"cannot read the tair program {path}: {e}") from None
    if text not in _CACHE:
        try:
            _CACHE[text] = parse(text)
        except TairError as e:
            raise ManifestError(f"tair: {e}") from None
    return _CACHE[text]


def evaluate(m: Manifest, values: dict, resolved) -> dict:
    """The oracle: the program in float64 on the manifest's inputs and scalars."""
    prog = load_text(m, m.reference)
    args = {q.name: (values[q.name] if q.name in values else resolved.scalars[q.name]) for q in prog.params}
    return _evaluate(prog, args, dtype=np.float64)
