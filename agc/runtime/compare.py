"""Compare a candidate's outputs with the expected ones.

An element passes when `|cand - ref| <= atol + rtol * |ref| + cond * scale` (NaN matches NaN,
infinities must match exactly). An element still holding the poison pattern where the reference
does not is reported as unwritten.
"""
from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

from ..manifest import Manifest
from .inputs import poison


@dataclass
class TensorReport:
    name: str
    ok: bool
    mismatches: int = 0
    unwritten: int = 0
    total: int = 0
    max_abs_err: float = 0.0
    max_rel_err: float = 0.0
    first: dict | None = None      # {"index", "got", "expected"} of the worst element

    def to_dict(self) -> dict:
        return self.__dict__.copy()


@dataclass
class CompareReport:
    case: str
    ok: bool
    tensors: list[TensorReport] = field(default_factory=list)

    def to_dict(self) -> dict:
        return {"case": self.case, "ok": self.ok, "tensors": [t.to_dict() for t in self.tensors]}


def compare_tensor(name: str, cand: np.ndarray, ref: np.ndarray, dt, rtol: float, atol: float,
                   cond: float = 0.0, scale: np.ndarray | None = None) -> TensorReport:
    total = int(ref.size)
    if cand.shape != ref.shape:
        return TensorReport(name, False, total, 0, total, first={"index": None, "got": f"shape {cand.shape}",
                                                                 "expected": f"shape {ref.shape}"})
    if total == 0:
        return TensorReport(name, True)
    pz = poison(ref.shape, dt)
    unwritten = (cand.view(dt.bits_view()) == pz) & (ref.view(dt.bits_view()) != pz)
    c, r = dt.from_storage(cand), dt.from_storage(ref)
    if dt.is_float:
        with np.errstate(invalid="ignore", over="ignore"):
            err = np.abs(c - r)
            bound = atol + rtol * np.abs(r) + (cond * scale if cond and scale is not None else 0.0)
            finite = np.isfinite(c) & np.isfinite(r)
            ok = finite & (err <= bound)
        ok |= np.isnan(c) & np.isnan(r)
        ok |= np.isinf(r) & (c == r)          # an infinity matches only the same infinity
        err = np.where(np.isfinite(err), err, np.where(ok, 0.0, np.inf))
    else:
        c64, r64 = c.astype(np.int64) if dt.kind != "uint" else c, r.astype(np.int64) if dt.kind != "uint" else r
        err = np.abs(c64.astype(np.float64) - r64.astype(np.float64))
        ok = c == r
    bad = ~ok
    n_bad = int(bad.sum())
    with np.errstate(invalid="ignore", divide="ignore"):
        rel = np.where(np.abs(r) > 0, err / np.abs(r.astype(np.float64)), 0.0)
    rep = TensorReport(name, n_bad == 0, n_bad, int((unwritten & bad).sum()), total,
                       float(err.max()), float(np.nanmax(rel)))
    if n_bad:
        idx = np.unravel_index(int(np.argmax(np.where(bad, err, -1.0))), ref.shape)
        rep.first = {"index": [int(i) for i in idx], "got": c[idx].item(), "expected": r[idx].item()}
    return rep


def compare_outputs(m: Manifest, case_label: str, cand: dict[str, np.ndarray], ref: dict[str, np.ndarray],
                    scale: dict[str, np.ndarray] | None = None) -> CompareReport:
    reports = []
    for p in m.outputs():
        rtol, atol = m.tolerance_for(p.name)
        reports.append(compare_tensor(p.name, cand[p.name], ref[p.name], p.dtype, rtol, atol,
                                      m.cond_for(p.name), (scale or {}).get(p.name)))
    return CompareReport(case_label, all(r.ok for r in reports), reports)
