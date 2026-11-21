#!/usr/bin/env python
"""Differential correctness of what agc ships on the LLM benchmark: every recorded recipe and every default-policy
result is run against the original binary (amdclang -O3 on the source as shipped) on the same inputs, every battery
case plus one case at the bench shapes, and the outputs are compared with each other.

    .venv/bin/python scripts/equivalence.py [KERNEL ...]   -> tests/baselines/llm-equivalence-gfx950.json
    .venv/bin/python scripts/equivalence.py --table
"""
from __future__ import annotations

import json
import sys
import tempfile
import time
from pathlib import Path

from agc import agent, corpus
from agc.session.policy import rebuild
from agc.session import Session, SessionError

BENCH = Path(__file__).resolve().parent.parent / "bench" / "llm"
OUT = corpus.BASELINES.with_name("llm-equivalence-gfx950.json")
POLICY = corpus.BASELINES.with_name("llm-gfx950.json")
KEYS = ("ok", "cases", "bit_identical", "bit_identical_cases", "within_tolerance", "max_abs_err", "max_rel_err", "worst_case")


def table(rec: dict) -> str:
    rows = ["| kernel | what | cases | bit-identical to the original binary | largest abs / rel difference | within tolerance |",
            "|---|---|---|---|---|---|"]
    for n, k in rec["kernels"].items():
        for what, r in k.items():
            if "error" in r:
                rows.append(f"| `{n}` | {what} | | error: {r['error']} | | |")
                continue
            same = "yes" if r["bit_identical"] else f"{r['bit_identical_cases']} of {r['cases']} cases"
            err = "" if r["bit_identical"] else f"{r['max_abs_err']:.3g} / {r['max_rel_err']:.3g}"
            rows.append(f"| `{n}` | {what} | {r['cases']} | {same} | {err} | {'yes' if r['within_tolerance'] else '**no**'} |")
    return "\n".join(rows)


def main(argv) -> int:
    rec = json.loads(OUT.read_text()) if OUT.exists() else {"kernels": {}}
    if argv == ["--table"]:
        print(table(rec))
        return 0
    rec.update(what="outputs of agc's states against the original binary (amdclang -O3, source as shipped) on the same inputs: "
                    "the battery's cases and one case at the bench shapes", recorded=time.strftime("%Y-%m-%d"))
    root = tempfile.mkdtemp(prefix="agc-eq-")
    pol = json.loads(POLICY.read_text())["kernels"]
    for n in argv or sorted(p.stem for p in BENCH.glob("*.json")):
        s = Session.open(BENCH / f"{n}.json", root)
        out = {}
        states = {}
        if s.base_id != s.ref_id:
            states["baseline (strongest amdclang build)"] = s.base_id
        d = agent.RECIPES / n
        if (d / "recipe.json").exists():
            recipe = json.loads((d / "recipe.json").read_text())
            states["session recipe"] = s.adopt((d / "best.s").read_text(), recipe["launch"], recipe["strict"])["id"]
        if n in pol and not pol[n]["fallback"]:
            how = pol[n]["chosen"]["how"]
            try:
                states[f"policy: {how}"] = rebuild(s, pol[n]["chosen"])
            except SessionError as e:
                out[f"policy: {how}"] = {"error": e.message[:200]}
        for what, sid in states.items():
            try:
                r = s.equivalent(sid)
                out[what] = {k: r.get(k) for k in KEYS} if r.get("ok") is not None and "error" not in r else {"error": str(r.get("error"))[:200]}
            except SessionError as e:
                out[what] = {"error": f"{e.kind}: {e.message}"[:200]}
            print(f"{n:24s} {what:44s} {json.dumps(out[what])[:150]}", flush=True)
        rec["kernels"][n] = out
        rec["kernels"] = dict(sorted(rec["kernels"].items()))
        OUT.write_text(json.dumps(rec, indent=1) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
