#!/usr/bin/env python
"""The LLM-kernel benchmark (`bench/llm`): the default policy on every kernel, against the kernel's baseline
(the strongest amdclang build, `scripts/strong_baseline.py`; amdclang -O3 on the source as shipped where there is none).

    .venv/bin/python scripts/llmbench.py [kernel ...]   -> tests/baselines/llm-gfx950.json
    .venv/bin/python scripts/llmbench.py --table        -> the Markdown table of the recorded results
"""
from __future__ import annotations

import json
import math
import sys
import tempfile
import time
from pathlib import Path

from agc import corpus
from agc.manifest import Manifest
from agc.runtime import toolchain
from agc.runtime.timing import PROTOCOL_VERSION
from agc.session import Session
from agc.session.policy import optimize

BENCH = Path(__file__).resolve().parent.parent / "bench" / "llm"
OUT = corpus.BASELINES.with_name("llm-gfx950.json")
LIBRARIES = ("flashinfer", "vllm", "rocblas", "miopen", "port")


def names() -> list[str]:
    return sorted(p.stem for p in BENCH.glob("*.json"))


def library(m: Manifest) -> str:
    return next((t for t in m.tags if t in LIBRARIES), "")


def summarize(kernels: dict) -> dict:
    sp = [k["chosen"]["speedup"] for k in kernels.values()]
    return {"kernels": len(kernels), "wins": sum(not k["fallback"] for k in kernels.values()),
            "fallbacks": sum(k["fallback"] for k in kernels.values()),
            "geomean": round(math.exp(sum(map(math.log, sp)) / len(sp)), 3) if sp else None}


def table(out: dict) -> str:
    rows = ["| kernel | library | baseline ms | agc ms | speedup (95% CI) | how | bit-identical |", "|---|---|---|---|---|---|---|"]
    for n, k in out["kernels"].items():
        c = k["chosen"]
        if k["fallback"]:
            rows.append(f"| `{n}` | {k['library']} | {k['amdclang_ms']:.4f} | | fallback (no verified win) | | |")
        else:
            rows.append(f"| `{n}` | {k['library']} | {c['amdclang_ms']:.4f} | {c['ms']:.4f} | **{c['speedup']:.2f}** "
                        f"({c['ci95'][0]:.2f} to {c['ci95'][1]:.2f}) | `{c['how']}` | {'yes' if c['bit_identical'] else 'no'} |")
    s = out["summary"]
    rows.append("")
    rows.append(f"{s['wins']} wins and {s['fallbacks']} fallbacks over {s['kernels']} kernels; geomean {s['geomean']} "
                f"with fallbacks counted as 1.0. Protocol `{out['protocol']}`, recorded {out['recorded']}.")
    return "\n".join(rows)


def main(argv) -> int:
    if argv == ["--table"]:
        print(table(json.loads(OUT.read_text())))
        return 0
    out = json.loads(OUT.read_text()) if OUT.exists() and argv else {"kernels": {}}
    out.update(protocol=PROTOCOL_VERSION, toolchain=toolchain.identity(), baseline="the strongest amdclang build per kernel (tests/baselines/llm-strong-gfx950.json)", recorded=time.strftime("%Y-%m-%d"))
    root = tempfile.mkdtemp(prefix="agc-llm-")
    for n in argv or names():
        s = Session.open(BENCH / f"{n}.json", root)
        r = optimize(s)
        c = r["chosen"]
        ref_ms = c.get("amdclang_ms") or next((row["amdclang_ms"] for row in r["candidates"] if row.get("amdclang_ms")), None)
        if ref_ms is None:
            ref_ms = s.bench("baseline")["candidate_ms"]       # no candidate was timed: time the baseline itself
        out["kernels"][n] = {"library": library(s.manifest), "amdclang_ms": ref_ms, "fallback": r["fallback"],
                             "chosen": {k: v for k, v in c.items() if k != "state"},
                             "candidates": [{k: v for k, v in row.items() if k != "state"} for row in r["candidates"]]}
        sp = "fallback" if r["fallback"] else f"{c['speedup']:.3f}x {c['ci95']}"
        print(f"{n:18s} {ref_ms:9.4f} ms  {c['path']:12s} {c['how']:44s} {sp}", flush=True)
    out["kernels"] = dict(sorted(out["kernels"].items()))
    out["summary"] = summarize(out["kernels"])
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    print(out["summary"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
