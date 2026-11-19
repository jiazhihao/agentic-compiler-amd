"""The kernel corpus: the manifests under `tests/kernels`."""
from __future__ import annotations

from pathlib import Path

from .manifest import Manifest

CORPUS_DIR = Path(__file__).resolve().parent.parent / "tests" / "kernels"
BASELINES = CORPUS_DIR.parent / "baselines" / "amdclang-gfx950.json"


def names() -> list[str]:
    return sorted(p.stem for p in CORPUS_DIR.glob("*.json"))


def load(name: str) -> Manifest:
    return Manifest.load(CORPUS_DIR / f"{name}.json")
