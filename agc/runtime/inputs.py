"""The input battery: seeded generators for several distributions, hidden seeds the agent
cannot see, and shape variants for dynamic symbols.

A `Case` is (distribution, seed, symbols): the worker regenerates it without transferring arrays.
"""
from __future__ import annotations

import hashlib
import os
import secrets
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

import numpy as np

from ..manifest import Manifest, Param, eval_expr, eval_scalar

DISTRIBUTIONS = ("normal", "uniform", "small_int", "large_exponent", "structured", "sparse_spikes")
PUBLIC_SEEDS = (0, 1, 2)
POISON_BYTE = 0xDA   # 0xDADADADA as f32 is about -3.08e16: never a plausible result


@dataclass(frozen=True)
class Case:
    distribution: str
    seed: int
    symbols: dict[str, int] = field(default_factory=dict, hash=False, compare=False)
    hidden: bool = False

    @property
    def label(self) -> str:
        sym = ",".join(f"{k}={v}" for k, v in sorted(self.symbols.items()))
        return f"{self.distribution}/{'hidden' if self.hidden else f'seed{self.seed}'}[{sym}]"

    def to_dict(self) -> dict:
        return {"distribution": self.distribution, "seed": self.seed, "symbols": self.symbols, "hidden": self.hidden}

    @staticmethod
    def from_dict(d: dict) -> "Case":
        return Case(d["distribution"], int(d["seed"]), dict(d.get("symbols", {})), bool(d.get("hidden", False)))


def hidden_secret(root: Path) -> bytes:
    """A per-installation secret from which hidden seeds are derived. Never exposed by the API."""
    p = Path(root) / "secret"
    if not p.exists():
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(secrets.token_bytes(32))
        os.chmod(p, 0o600)
    return p.read_bytes()


def hidden_seed(secret: bytes, manifest_name: str, index: int) -> int:
    h = hashlib.sha256(secret + manifest_name.encode() + index.to_bytes(4, "little")).digest()
    return int.from_bytes(h[:4], "little")


def shape_variants(m: Manifest) -> list[dict[str, int]]:
    """The manifest shapes, plus neighbours of each dynamic symbol (1, v-1, v+1, a larger one)
    to catch code keyed to one size or to a multiple of the block size."""
    base = dict(m.shapes)
    variants = [base]
    for s in m.dynamic:
        v = base[s]
        for cand in (1, v - 1, v + 1, 2 * v if v <= 64 else v + 7):
            alt = {**base, s: cand}
            if cand >= 1 and alt not in variants:
                try:
                    m.resolve(alt)
                except ValueError:
                    continue
                variants.append(alt)
    return variants


def build_battery(m: Manifest, secret: bytes, quick: bool = False) -> list[Case]:
    """Public cases plus hidden cases. `quick`: one public case per shape variant."""
    variants = shape_variants(m)
    if quick:
        return [Case("normal", 0, v) for v in variants]
    cases: list[Case] = []
    for i, sym in enumerate(variants):
        for dist in DISTRIBUTIONS:
            for s in (PUBLIC_SEEDS if i == 0 else PUBLIC_SEEDS[:1]):
                cases.append(Case(dist, s, sym))
        for j in range(3 if i == 0 else 1):
            dist = DISTRIBUTIONS[(i * 7 + j * 3) % len(DISTRIBUTIONS)]
            cases.append(Case(dist, hidden_seed(secret, m.name, i * 16 + j), sym, hidden=True))
    return cases


def public_view(cases: Iterable[Case]) -> list[dict]:
    """What the agent may see: hidden cases without their seed."""
    return [{**c.to_dict(), **({"seed": None} if c.hidden else {})} for c in cases]


def _rng(case: Case, param: Param) -> np.random.Generator:
    h = hashlib.sha256(f"{case.distribution}|{case.seed}|{param.name}".encode()).digest()
    return np.random.default_rng(int.from_bytes(h[:8], "little"))


_FP8_MAX = {"e4m3": 448.0, "e5m2": 57344.0}


def generate(param: Param, shape: tuple[int, ...], case: Case) -> np.ndarray:
    """One input tensor in its storage dtype. `param.init` overrides the case distribution."""
    rng = _rng(case, param)
    n = int(np.prod(shape))
    dt, init = param.dtype, param.init
    if init == "zeros":
        return np.zeros(shape, dtype=dt.storage)
    if isinstance(init, dict):
        if init.get("kind") == "constant":
            v = eval_scalar(init["value"], case.symbols) if dt.is_float else eval_expr(init["value"], case.symbols)
            return np.full(shape, v).astype(dt.storage)
        if init.get("kind") == "int_range":
            lo, hi = eval_expr(init.get("lo", 0), case.symbols), eval_expr(init["hi"], case.symbols)
            return rng.integers(lo, hi, size=n).astype(dt.storage).reshape(shape)
        raise ValueError(f"param {param.name}: unknown init {init!r}")
    dist = init or case.distribution
    if dt.is_float:
        x = _float_values(dist, rng, n)
        if dt in _FP8_MAX and n:                       # scale wide distributions instead of saturating
            top, cap = float(np.abs(x).max()), _FP8_MAX[dt] / 4
            if top > cap:
                x = x * (cap / top)
        if dt in ("f16", "bf16") and dist == "large_exponent":
            x = np.clip(x, -1e4, 1e4)
        return dt.to_storage(x).reshape(shape)
    if dt.kind == "bool":
        return (rng.integers(0, 2, size=n) != 0).reshape(shape)
    info = np.iinfo(dt.storage)
    span = {"small_int": 3, "structured": 3, "sparse_spikes": 1}.get(dist, 100)
    lo, hi = max(info.min, -span if dist != "sparse_spikes" else 0), min(info.max, span)
    return rng.integers(lo, hi + 1, size=n).astype(dt.storage).reshape(shape)


def generate_inputs(m: Manifest, resolved, case: Case) -> dict[str, np.ndarray]:
    return {p.name: generate(p, resolved.tensors[p.name], case) for p in m.inputs()}


def _float_values(dist: str, rng: np.random.Generator, n: int) -> np.ndarray:
    if dist == "normal":
        return rng.standard_normal(n)
    if dist == "uniform":
        return rng.uniform(-1.0, 1.0, n)
    if dist == "small_int":
        return rng.integers(-3, 4, size=n).astype(np.float64)
    if dist == "large_exponent":
        return np.sign(rng.standard_normal(n)) * 10.0 ** rng.uniform(-6, 6, n)
    if dist == "structured":      # ramps with a few spikes: exposes transposed or shifted indexing
        i = np.arange(n, dtype=np.float64)
        x = ((i % 97) - 48) / 48.0
        mask = rng.uniform(0, 1, n) < 0.05
        x[mask] = 1.0 + (i[mask] % 7)
        return x
    if dist == "sparse_spikes":
        x = np.zeros(n)
        if n:
            idx = rng.choice(n, size=max(1, n // 50), replace=False)
            x[idx] = rng.standard_normal(idx.size) * 100.0
        return x
    raise ValueError(f"unknown distribution {dist!r}")


def poison(shape, dt) -> np.ndarray:
    return np.full(int(np.prod(shape)) * dt.itemsize, POISON_BYTE, np.uint8).view(dt.bits_view()).reshape(shape)
