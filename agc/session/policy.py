"""The default policy: what agc does with a manifest when nobody steers it.

Candidates: the amdclang import with `unroll_loads` at each factor (when a loop qualifies) and with
`coarsen` at each factor (several workgroups of the original per launched workgroup), and the
manifest's tensor program compiled with every parameter of the matching template. Each candidate
goes through the static checks, the full battery and a paired timing against amdclang. The result
is the verified state with the best lower confidence bound among the wins; with no win it is the
amdclang build itself, reported as a fallback and never as a speedup.
"""
from __future__ import annotations

import itertools

from .session import Session, SessionError

UNROLL_FACTORS = (4, 8, 16)
COARSEN_FACTORS = (2, 4, 8)


def candidates(s: Session) -> list[dict]:
    out = []
    if s.ref_id is not None:
        for f in UNROLL_FACTORS:
            out.append({"path": "import+pass", "how": f"unroll_loads(factor={f})", "bit_identical": True,
                        "make": lambda f=f: s.apply("ref", "unroll_loads", {"factor": f})})
        for f in COARSEN_FACTORS:
            out.append({"path": "import+pass", "how": f"coarsen(factor={f})", "bit_identical": True,
                        "make": lambda f=f: s.apply("ref", "coarsen", {"factor": f})})
    if s.manifest.program is not None:
        from .. import gen
        try:
            names = gen.applicable(s.manifest)
        except gen.GenError:
            names = []
        for t in names:
            space = gen.TEMPLATES[t]["params"]
            for values in itertools.product(*space.values()):
                params = dict(zip(space, values))
                out.append({"path": "generate", "how": f"{t}({', '.join(f'{k}={v}' for k, v in params.items())})",
                            "bit_identical": False, "make": lambda t=t, params=params: s.generate(t, params)})
    return out


def optimize(s: Session, log=None) -> dict:
    rows = []
    skipped = set()
    for c in candidates(s):
        row = {"path": c["path"], "how": c["how"], "bit_identical": c["bit_identical"]}
        family = c["how"].split("(")[0]
        if family in skipped:
            continue
        try:
            st = c["make"]()
            row["state"] = st["id"]
            b = s.bench(st["id"])                          # static check and battery first; refusals raise
            row.update(verified=True, outcome=b["outcome"], speedup=b.get("speedup"), ci95=b.get("speedup_ci95"),
                       ms=b.get("candidate_ms"), amdclang_ms=b.get("reference_ms"))
        except SessionError as e:
            row.update(verified=False, outcome="rejected", reason=f"{e.kind}: {e.message}"[:300])
            if e.kind == "parameter" and c["path"] == "import+pass":
                skipped.add(family)                        # the pass does not apply to this kernel at all
        rows.append(row)
        if log:
            log(row)
    wins = [r for r in rows if r.get("outcome") == "win"]
    report = {"kernel": s.manifest.name, "session": s.id, "candidates": rows}
    if wins:
        best = max(wins, key=lambda r: r["ci95"][0])
        s.store.tag("best", best["state"])
        report.update(fallback=False, chosen={k: best[k] for k in ("state", "path", "how", "bit_identical", "speedup", "ci95", "ms", "amdclang_ms")})
    elif s.ref_id is not None:
        s.store.tag("best", s.ref_id)
        report.update(fallback=True, chosen={"state": s.ref_id, "path": "amdclang", "how": "the amdclang build (no verified win)",
                                              "bit_identical": True, "speedup": 1.0, "ci95": None})
    else:
        timed = [r for r in rows if r.get("outcome") == "no_baseline"]
        if not timed:
            raise SessionError("verification", "no candidate passed verification and the manifest has no HIP source to fall back to")
        best = min(timed, key=lambda r: r["ms"])
        s.store.tag("best", best["state"])
        report.update(fallback=False, chosen={"state": best["state"], "path": best["path"], "how": best["how"],
                                               "bit_identical": False, "speedup": None, "ci95": None, "ms": best["ms"]})
    return report
