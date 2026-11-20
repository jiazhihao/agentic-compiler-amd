#!/usr/bin/env python
"""The strongest amdclang build per LLM-benchmark kernel: what agc's results are measured against.

    .venv/bin/python scripts/strong_baseline.py seed [KERNEL ...]  candidates from the recorded session recipes (their amdclang-built source)
    .venv/bin/python scripts/strong_baseline.py run [KERNEL ...]   measure the candidates, write the manifests' `baseline` and the record
    .venv/bin/python scripts/strong_baseline.py promote KERNEL     the baseline candidate of the kernel's last agent session, then `run`

Candidates per kernel: the source as shipped and the manifest's current `baseline` source (a
restructured source an agent session found, with its launch), each with and without `-ffast-math`.
All are amdclang builds. Each must pass the full battery; each is timed against amdclang -O3 on the
source as shipped; the best one is confirmed with the harness's rule (two valid 240-pair timings,
the lower one counts). Without a confirmed win the baseline stays -O3 on the source as shipped.
"""
from __future__ import annotations

import json
import sys
import tempfile
import time
from pathlib import Path

from agc import agent, corpus
from agc.agent import runner
from agc.manifest import Manifest
from agc.runtime.timing import PROTOCOL_VERSION
from agc.session import Session, SessionError

BENCH = Path(__file__).resolve().parent.parent / "bench" / "llm"
SOURCES = BENCH / "baselines"
OUT = corpus.BASELINES.with_name("llm-strong-gfx950.json")
FAST = "-ffast-math"


def names() -> list[str]:
    return sorted(p.stem for p in BENCH.glob("*.json"))


def raw(name: str) -> dict:
    return json.loads((BENCH / f"{name}.json").read_text())


def put(name: str, baseline: dict | None) -> None:
    d = raw(name)
    d.pop("baseline", None)
    if baseline:
        d["baseline"] = baseline
    (BENCH / f"{name}.json").write_text(json.dumps(d, indent=1) + "\n")


def plain(name: str, root) -> Session:
    """A session whose baseline is amdclang -O3 on the source as shipped, whatever the manifest says."""
    d = raw(name)
    d.pop("baseline", None)
    return Session.from_manifest(Manifest.from_dict(d, BENCH / f"{name}.json"), root)


def candidate(name: str, text: str, c: dict) -> None:
    """Make a candidate (source text, launch, flags, defines) the manifest's baseline, unmeasured."""
    SOURCES.mkdir(exist_ok=True)
    (SOURCES / f"{name}.hip").write_text(text)
    put(name, {"source": f"baselines/{name}.hip", **{k: c[k] for k in ("flags", "defines", "launch") if c.get(k)}})


def seed(only: list[str], root=".agc") -> None:
    for d in sorted(p for p in agent.RECIPES.iterdir() if (p / "best.s").exists() and (not only or p.name in only)):
        s = plain(d.name, root)
        best = (d / "best.s").read_text()
        launch = json.loads((d / "recipe.json").read_text())["launch"]
        st = next((x for x in s.store.all_states() if x.ir == best and s.launch_of(x.id) == launch), None)
        own = runner.own_source(s, st.id) if st else None
        if own is None:
            print(f"{d.name:24s} no source state behind the recipe")
            continue
        candidate(d.name, Path(own["file"]).read_text(), own)
        print(f"{d.name:24s} {own['flags']} {own['defines']} {own['launch']}")


def measure(name: str, root) -> dict:
    s = plain(name, root)
    bl = raw(name).get("baseline") or {}
    shipped = Path(s.manifest.source).read_text()
    cands = [{"what": "shipped source", "text": shipped, "flags": [FAST]}]
    if bl:
        text = (BENCH / bl["source"]).read_text() if bl.get("source") else shipped
        flags = [f for f in bl.get("flags", []) if f != FAST]
        for fl in (flags, [*flags, FAST]):
            if text != shipped or bl.get("launch") or bl.get("defines") or flags:
                cands.append({"what": "restructured source" if text != shipped else "shipped source", "text": text, "flags": fl,
                              "launch": bl.get("launch"), "defines": bl.get("defines"), "source": bl.get("source") if text != shipped else None})
    rows = []
    for c in cands:
        row = {k: c.get(k) for k in ("what", "flags", "defines", "launch")}
        try:
            st = s.source(c["text"], launch=c.get("launch"), defines=c.get("defines"), flags=c["flags"], short_defines=True)
            c["state"] = st["id"]
            if s.store.get(st["id"]).ir == s.store.get(s.ref_id).ir and not c.get("launch"):
                row.update(outcome="identical code")
            else:
                b = s.bench(st["id"], 120)
                row.update(outcome=b["outcome"], speedup=b.get("speedup"), ci95=b.get("speedup_ci95"), ms=b.get("candidate_ms"))
        except SessionError as e:
            row.update(outcome="rejected", reason=f"{e.kind}: {e.message}"[:300])
        rows.append(row)
        print(f"  {name:24s} {c['what']:20s} {' '.join(c['flags']):14s} {row['outcome']:10s} {row.get('speedup', '')} {row.get('ci95', '')}", flush=True)
    out = {"candidates": rows, "amdclang_O3_ms": s.bench("ref")["candidate_ms"], "baseline": None, "over_shipped_O3": 1.0}
    order = sorted((i for i, r in enumerate(rows) if r["outcome"] == "win"), key=lambda i: -rows[i]["ci95"][0])
    for i in order:                                          # the harness's rule on the best candidate; the next one if it does not hold
        v = runner.verify(s, cands[i]["state"])
        rows[i]["verified"] = {k: v.get(k) for k in ("outcome", "speedup", "speedup_ci95", "candidate_ms", "cases", "runs")}
        if v.get("ok") and v.get("outcome") == "win":
            c = cands[i]
            out.update(baseline={**({"source": c["source"]} if c.get("source") else {}),
                                 **{k: c[k] for k in ("flags", "defines", "launch") if c.get(k)}},
                       over_shipped_O3=v["speedup"], ci95=v["speedup_ci95"], ms=v["candidate_ms"])
            break
    return out


def run(kernels: list[str], root=None) -> None:
    root = root or tempfile.mkdtemp(prefix="agc-strong-")
    rec = json.loads(OUT.read_text()) if OUT.exists() else {"kernels": {}}
    rec.update(what="the strongest amdclang build per kernel (see scripts/strong_baseline.py); speedups are over amdclang -O3 on the "
                    "source as shipped; the baseline is what agc's results are measured against",
               protocol=PROTOCOL_VERSION, recorded=time.strftime("%Y-%m-%d"))
    for n in kernels or names():
        r = measure(n, root)
        put(n, r["baseline"])
        if not (r["baseline"] or {}).get("source") and (SOURCES / f"{n}.hip").exists():
            (SOURCES / f"{n}.hip").unlink()
        rec["kernels"][n] = r
        rec["kernels"] = dict(sorted(rec["kernels"].items()))
        OUT.write_text(json.dumps(rec, indent=1) + "\n")
        print(f"{n:24s} baseline: {r['baseline'] or '-O3 on the source as shipped'}  {r['over_shipped_O3']}x over shipped -O3", flush=True)


def promote(name: str, root=".agc") -> bool:
    s = Session.open(BENCH / f"{name}.json", root)
    res = json.loads((s.store.root / "harness-result.json").read_text())
    c = res.get("baseline_candidate")
    if not c:
        print(f"{name}: the last session has no baseline candidate")
        return False
    old = raw(name).get("baseline") or {}
    c = dict(c)
    if old.get("launch") and not c.get("launch"):            # a source state without its own launch runs with the manifest's
        c["launch"] = None
    candidate(name, Path(c["file"]).read_text(), c)
    return True


def main(argv) -> int:
    if argv[:1] == ["seed"]:
        seed(argv[1:])
    elif argv[:1] == ["run"]:
        run(argv[1:])
    elif argv[:1] == ["promote"] and len(argv) == 2:
        if promote(argv[1]):
            run([argv[1]])
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
