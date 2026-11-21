"""Translation checks on the CPU: the lowering's intermediate programs, run by their interpreters
on battery inputs at reduced shapes.

- `kir` against the manifest's reference, under the manifest's tolerance: the frontend and the
  `kir` passes kept the meaning of the source.
- `wir` against `kir`, bit for bit: wave lowering kept it, and every value declared uniform is.

They need no GPU and no toolchain, so CI runs them; the battery on the device remains the gate for
the emitted code.
"""
from __future__ import annotations

import numpy as np

from ..kir.interp import InterpError, run as run_kir_func
from ..manifest import Manifest
from ..runtime import reference
from ..runtime.compare import compare_outputs
from ..runtime.inputs import Case, generate_inputs, poison
from ..wir.interp import run as run_wir_func

SMALL = (1, 257, 1000)          # sizes to interpret: one element, not a multiple of a wave, several workgroups


def cpu_cases(m: Manifest, limit: int = 1 << 20) -> list[Case]:
    """Battery cases small enough to interpret: the dynamic symbols reduced, two distributions. With several
    dynamic symbols each one gets the root of the size, so that the work (their product) stays the same."""
    out, seen = [], set()
    d = max(1, len(m.dynamic))
    for size in SMALL:
        v = max(1, round(size ** (1.0 / d)))
        if v in seen:
            continue
        seen.add(v)
        sym = {**m.shapes, **{s: v for s in m.dynamic}}
        try:
            r = m.resolve(sym)
        except ValueError:
            continue
        if sum(int(np.prod(s)) for s in r.tensors.values()) > limit or int(np.prod(r.grid)) * int(np.prod(r.block)) > limit:
            continue
        out += [Case("normal", 0, sym), Case("small_int", 1, sym)]
    return out


def _tensors(m: Manifest, resolved, case: Case) -> dict[str, np.ndarray]:
    inputs = generate_inputs(m, resolved, case)
    out = {}
    for p in m.params:
        if p.kind == "tensor":
            a = inputs[p.name] if p.role in ("in", "inout") else poison(resolved.tensors[p.name], p.dtype)
            out[p.name] = np.ascontiguousarray(a).view(p.dtype.storage).copy()
    return out


def run_kir(m: Manifest, f, case: Case) -> dict[str, np.ndarray]:
    """The outputs of the `kir` function `f` on a battery case."""
    r = m.resolve(case.symbols)
    t = _tensors(m, r, case)
    args = {fp.name: (t[mp.name] if mp.kind == "tensor" else r.scalars[mp.name]) for fp, mp in zip(f.params, m.params)}
    run_kir_func(f, args, r.grid, r.block)
    return {p.name: t[p.name] for p in m.outputs()}


def run_wir(m: Manifest, w, layout: list, case: Case) -> dict[str, np.ndarray]:
    r = m.resolve(case.symbols)
    t = _tensors(m, r, case)
    values = {off: (t[mp.name] if mp.kind == "tensor" else r.scalars[mp.name]) for (off, _), mp in zip(layout, m.params)}
    run_wir_func(w, r.grid, r.block, values)
    return {p.name: t[p.name] for p in m.outputs()}


def cpu_check(m: Manifest, lowered, cases: list[Case] | None = None) -> dict:
    """{"ok", "cases": [...]}: per case whether `kir` meets the reference and `wir` equals `kir`."""
    cases = cpu_cases(m) if cases is None else cases
    rows = []
    for case in cases:
        row = {"case": case.label}
        try:
            r = m.resolve(case.symbols)
            k = run_kir(m, lowered.kir_func, case)
            inputs = generate_inputs(m, r, case)
            rep = compare_outputs(m, case.label, k, reference.evaluate(m, inputs, r), reference.scale(m, inputs, r))
            row["kir_meets_reference"] = bool(rep.ok)
            if not rep.ok:
                row["kir_report"] = rep.to_dict()
            w = run_wir(m, lowered.wir_func, lowered.layout, case)
            row["wir_equals_kir"] = all(np.array_equal(k[n].view(np.uint8), w[n].view(np.uint8)) for n in k)
        except InterpError as e:
            row["error"] = str(e)
        row["ok"] = bool(row.get("kir_meets_reference") and row.get("wir_equals_kir"))
        rows.append(row)
    return {"ok": bool(rows) and all(r["ok"] for r in rows), "cases": rows}
