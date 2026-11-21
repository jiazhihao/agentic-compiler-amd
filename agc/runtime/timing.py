"""The timing protocol. The version string is stored with every measurement.

agc-timing-amd-2 (the Codex review of #16): as agc-timing-amd-1, and the launch is prepared (arguments
  packed, ctypes conversion done) before the start event, so the interval between the two events
  holds only the submission call and the kernel. Measurements of the two versions are not comparable
  for short kernels.

Placements (issue #66; an option of paired comparisons, recorded as `placements` in the result): the
  time of a memory-bound kernel depends on where its tensors were allocated, by up to 6 % and
  differently for each code object, and stays the same for the life of the allocation. The same
  virtual addresses give different times, so it is not visible from user space. One allocation
  therefore measures one placement: on `rb_axpy` the speedup of one candidate over the baseline was
  0.97 to 1.05 across allocations with within-allocation CIs of +/- 0.5 %. With `placements` = K the
  tensors are freed and allocated again K times (a kept spacer in between), the pairs are spread
  evenly, and the statistic is the mean over the placements of the median log ratio with Student's t
  CI over the placements. The session uses 10 pairs per placement; the harness verifies with 24.

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
    placements: int = 1              # paired comparison: allocations of the tensors the pairs are spread over
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


def paired_summary(ref_ms: list[float], cand_ms: list[float], noise_floor: float = 0.0, per_placement: int | None = None) -> dict:
    """Speedup of the candidate over the reference from interleaved samples. `win` / `loss` need
    the whole 95 % CI beyond the noise floor.

    With `per_placement` (pairs per allocation of the tensors) the unit of the statistic is the placement:
    the speedup is the mean of the placements' median log ratios and the CI is Student's t over them, so
    it covers what differs between allocations as well as within one."""
    r, c = np.asarray(ref_ms, np.float64), np.asarray(cand_ms, np.float64)
    logs = np.log(r / c)
    extra = {}
    if per_placement and logs.size >= 3 * per_placement:
        meds = np.array([np.median(logs[i:i + per_placement]) for i in range(0, logs.size, per_placement)])
        k = meds.size
        half = float(_T975[min(k - 1, len(_T975) - 1)] * meds.std(ddof=1) / np.sqrt(k))
        mid, lo, hi = float(meds.mean()), float(meds.mean()) - half, float(meds.mean()) + half
        refs = [float(np.median(r[i:i + per_placement])) for i in range(0, r.size, per_placement)]
        extra = {"placements": int(k), "placement_speedups": [float(x) for x in np.exp(meds)], "placement_reference_ms": refs}
    else:
        lo, hi = bootstrap_median_ci(logs, reps=1000)
        mid = float(np.median(logs))
    speedup, interval = float(np.exp(mid)), [float(np.exp(lo)), float(np.exp(hi))]
    outcome = "win" if interval[0] > 1.0 + noise_floor else "loss" if interval[1] < 1.0 / (1.0 + noise_floor) else "parity"
    return {"speedup": speedup, "speedup_ci95": interval, "outcome": outcome, "pairs": int(r.size), **extra,
            "reference": summarize(ref_ms), "candidate": summarize(cand_ms)}


# two-sided 95 % quantiles of Student's t by degrees of freedom (index 0 unused)
_T975 = (0.0, 12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, 2.262, 2.228, 2.201, 2.179, 2.160, 2.145, 2.131,
         2.120, 2.110, 2.101, 2.093, 2.086, 2.080, 2.074, 2.069, 2.064, 2.060, 2.056, 2.052, 2.048, 2.045, 2.042)
