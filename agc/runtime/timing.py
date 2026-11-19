"""The timing protocol. The version string is stored with every measurement.

agc-timing-amd-2 (the Codex review of #16): as agc-timing-amd-1, and the launch is prepared (arguments
  packed, ctypes conversion done) before the start event, so the interval between the two events
  holds only the submission call and the kernel. Measurements of the two versions are not comparable
  for short kernels.

agc-timing-amd-1:
  - one stream owned by the harness; `hipEvent`s around a single launch
  - before every launch: outputs re-poisoned and inout tensors restored (device-side copies),
    then the caches are flushed by writing a buffer larger than L2 + MALL (policy `flush`), or
    left as the previous launch left them (policy `warm`)
  - warmup, then samples until the bootstrap 95 % CI of the median is within `target_rel_ci`,
    bounded by `min_iters` / `max_iters`
  - the outputs of the last timed launch are compared with the reference
  - clocks cannot be locked on an SR-IOV virtual function: the clock state is recorded, and
    comparisons between two code objects are *paired*: both are loaded in one process and
    launched alternately in a balanced random order; the statistic is the median of
    log(reference / candidate) with a bootstrap CI, and the outcome is `win` or `loss` only when
    the whole CI lies beyond `noise_floor` (1 %, the band of the A/A controls).
"""
from __future__ import annotations

from dataclasses import asdict, dataclass

import numpy as np

PROTOCOL_VERSION = "agc-timing-amd-2"


@dataclass
class TimingProtocol:
    version: str = PROTOCOL_VERSION
    warmup: int = 10
    min_iters: int = 30
    max_iters: int = 300
    target_rel_ci: float = 0.02
    cache: str = "flush"             # "flush" | "warm"
    pairs: int = 60                  # paired comparison: launches of each code object
    noise_floor: float = 0.01        # a paired result is a win or a loss only beyond 1 +/- this (the A/A band)
    case_distribution: str = "normal"
    case_seed: int = 0

    def to_dict(self) -> dict:
        return asdict(self)

    @staticmethod
    def from_dict(d: dict | None) -> "TimingProtocol":
        p = TimingProtocol()
        for k, v in (d or {}).items():
            if not hasattr(p, k):
                raise ValueError(f"unknown timing protocol field {k!r}")
            setattr(p, k, v)
        if p.version != PROTOCOL_VERSION:
            raise ValueError(f"unsupported timing protocol {p.version!r}")
        if p.cache not in ("flush", "warm"):
            raise ValueError(f"cache policy must be flush or warm, got {p.cache!r}")
        return p


def bootstrap_median_ci(a: np.ndarray, reps: int = 400, seed: int = 0) -> tuple[float, float]:
    a = np.asarray(a, dtype=np.float64)
    if a.size < 3:
        m = float(np.median(a))
        return (m, m)
    idx = np.random.default_rng(seed).integers(0, a.size, size=(reps, a.size))
    meds = np.median(a[idx], axis=1)
    return (float(np.percentile(meds, 2.5)), float(np.percentile(meds, 97.5)))


def summarize(samples: list[float]) -> dict:
    a = np.asarray(samples, dtype=np.float64)
    lo, hi = bootstrap_median_ci(a)
    return {"n": int(a.size), "min_ms": float(a.min()), "median_ms": float(np.median(a)),
            "mean_ms": float(a.mean()), "std_ms": float(a.std(ddof=1)) if a.size > 1 else 0.0,
            "p10_ms": float(np.percentile(a, 10)), "p90_ms": float(np.percentile(a, 90)),
            "ci95_median_ms": [lo, hi]}


def converged(samples: list[float], proto: TimingProtocol) -> bool:
    if len(samples) < proto.min_iters:
        return False
    a = np.asarray(samples)
    lo, hi = bootstrap_median_ci(a, reps=200)
    med = float(np.median(a))
    return med > 0 and (hi - lo) / 2 <= proto.target_rel_ci * med


def paired_orders(pairs: int, seed: int = 0) -> list[bool]:
    """For each pair, whether the candidate is launched first: balanced and shuffled."""
    first = np.array([i % 2 == 0 for i in range(pairs)])
    np.random.default_rng(seed).shuffle(first)
    return [bool(x) for x in first]


def paired_summary(ref_ms: list[float], cand_ms: list[float], noise_floor: float = 0.0) -> dict:
    """Speedup of the candidate over the reference from interleaved samples. `win` / `loss` need
    the whole 95 % CI beyond the noise floor: the within-run CI does not see run-to-run effects
    (placement, clock level), which the A/A controls put at up to about 1 %."""
    r, c = np.asarray(ref_ms, np.float64), np.asarray(cand_ms, np.float64)
    logs = np.log(r / c)
    lo, hi = bootstrap_median_ci(logs, reps=1000)
    speedup, interval = float(np.exp(np.median(logs))), [float(np.exp(lo)), float(np.exp(hi))]
    outcome = "win" if interval[0] > 1.0 + noise_floor else "loss" if interval[1] < 1.0 / (1.0 + noise_floor) else "parity"
    return {"speedup": speedup, "speedup_ci95": interval, "outcome": outcome, "pairs": int(r.size),
            "reference": summarize(ref_ms), "candidate": summarize(cand_ms)}
