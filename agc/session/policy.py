"""The default policy: what agc does with a manifest when nobody steers it.

Candidates: the baseline (the strongest amdclang build, see the manifest's `baseline`) with `unroll_loads` at each factor (when a loop qualifies) and with
`coarsen` at each factor (several workgroups of the original per launched workgroup), `stream_loads`
(non-temporal loads) and `throttle`
(an LDS reservation that limits the workgroups per compute unit), and the
manifest's tensor program compiled with every parameter of the matching template. Each candidate
goes through the static checks, the full battery and a paired timing against amdclang. The result
is the verified state with the best lower confidence bound among the wins; with no win it is the
amdclang build itself, reported as a fallback and never as a speedup.
"""
from __future__ import annotations

import itertools

from .session import Session, SessionError

UNROLL_FACTORS = (4, 8, 16)
OWN_LOOPS = (4, 8, 16)                 # agc's own lowering: loop.unroll with loop.inflight=first
COARSEN_FACTORS = (2, 4, 8)
THROTTLE = (4,)                        # 2 and 1 per compute unit lost on every kernel of the LLM benchmark


def candidates(s: Session, own: bool = False) -> list[dict]:
    """`own`: also the HIP source through agc's own lowering (roadmap phase 2): the default plan, and the loop
    decisions. Not in the default policy yet: its records and tests are those of the import path until the own
    path covers the benchmark (roadmap M15, M21)."""
    out = []
    if own and s.manifest.source is not None:
        out.append({"path": "lower", "how": "lower()", "bit_identical": None, "make": lambda: s.lower()})
        for n in OWN_LOOPS:
            out.append({"path": "lower", "how": f"lower.loops(loop.unroll={n}, loop.inflight=first)", "bit_identical": None,
                        "make": lambda n=n: s.lower({"loop.unroll": n, "loop.inflight": "first"})})
    if s.ref_id is not None:
        for f in UNROLL_FACTORS:
            out.append({"path": "import+pass", "how": f"unroll_loads(factor={f})", "bit_identical": True,
                        "make": lambda f=f: s.apply("baseline", "unroll_loads", {"factor": f})})
        for f in COARSEN_FACTORS:
            out.append({"path": "import+pass", "how": f"coarsen(factor={f})", "bit_identical": True,
                        "make": lambda f=f: s.apply("baseline", "coarsen", {"factor": f})})
        out.append({"path": "import+pass", "how": "stream_loads(scope=all)", "bit_identical": True,
                    "make": lambda: s.apply("baseline", "stream_loads", {"scope": "all"})})
        for n in THROTTLE:
            out.append({"path": "import+pass", "how": f"throttle(workgroups_per_cu={n})", "bit_identical": True,
                        "make": lambda n=n: s.apply("baseline", "throttle", {"workgroups_per_cu": n})})
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


def rebuild(s: Session, chosen: dict) -> str:
    """The state a policy result describes (`path`, `how`), made again in session `s`: its id."""
    import re
    sid = "baseline"
    for step in chosen["how"].split(" + "):
        name, args = re.fullmatch(r"(\w+)\((.*)\)", step).groups()
        params = {}
        for kv in filter(None, (x.strip() for x in args.split(","))):
            key, v = kv.split("=")
            params[key] = int(v) if v.lstrip("-").isdigit() else v
        sid = (s.generate(name, params) if chosen["path"] == "generate" and sid == "baseline" else s.apply(sid, name, params))["id"]
    return sid


def warm_control(s: Session, state: str) -> dict:
    """The same paired timing with the caches as the previous launch left them."""
    try:
        w = s.bench_warm(state)
        return {k: w.get(k) for k in ("outcome", "speedup", "speedup_ci95", "reference_ms", "candidate_ms")}
    except SessionError as e:
        return {"outcome": "rejected", "reason": f"{e.kind}: {e.message}"[:200]}


def optimize(s: Session, log=None, own: bool = False) -> dict:
    rows = []
    skipped = set()
    for c in candidates(s, own):
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
            if row["bit_identical"] is None:               # the own lowering: bit-identity is measured, not assumed
                row["bit_identical"] = bool(s.equivalent(st["id"], "ref").get("bit_identical")) if s.ref_id else False
        except SessionError as e:
            row.update(verified=False, outcome="rejected", reason=f"{e.kind}: {e.message}"[:300])
            if e.kind == "parameter" and c["path"] in ("import+pass", "lower"):
                skipped.add(family)                        # the pass or the decision does not apply to this kernel at all
            if e.kind in ("frontend", "unsupported") and c["path"] == "lower":
                skipped.update({"lower", "lower.loops"})   # the own lowering does not take this kernel yet
        rows.append(row)
        if log:
            log(row)
    # non-temporal loads combine with the other transformations: try them on top of the best other win
    others = [r for r in rows if r.get("outcome") == "win" and not r["how"].startswith("stream_loads")]
    if others and s.ref_id is not None:
        top = max(others, key=lambda r: r["ci95"][0])
        row = {"path": top["path"], "how": f"{top['how']} + stream_loads(scope=all)", "bit_identical": top["bit_identical"]}
        try:
            st = s.apply(top["state"], "stream_loads", {"scope": "all"})
            row["state"] = st["id"]
            b = s.bench(st["id"])
            row.update(verified=True, outcome=b["outcome"], speedup=b.get("speedup"), ci95=b.get("speedup_ci95"),
                       ms=b.get("candidate_ms"), amdclang_ms=b.get("reference_ms"))
        except SessionError as e:
            row.update(verified=False, outcome="rejected", reason=f"{e.kind}: {e.message}"[:300])
        rows.append(row)
        if log:
            log(row)
    wins = [r for r in rows if r.get("outcome") == "win"]
    report = {"kernel": s.manifest.name, "session": s.id, "candidates": rows}
    if wins:
        best = max(wins, key=lambda r: r["ci95"][0])
        s.store.tag("best", best["state"])
        report.update(fallback=False, chosen={k: best[k] for k in ("state", "path", "how", "bit_identical", "speedup", "ci95", "ms", "amdclang_ms")})
        if "stream_loads" in best["how"]:                    # what non-temporal loads gain depends on what the caches hold
            report["chosen"]["warm"] = warm_control(s, best["state"])
    elif s.ref_id is not None:
        s.store.tag("best", s.base_id)
        report.update(fallback=True, chosen={"state": s.base_id, "path": "amdclang", "how": "the amdclang build (no verified win)",
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
