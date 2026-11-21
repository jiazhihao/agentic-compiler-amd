#!/usr/bin/env python
"""Run the default policy on every corpus kernel (and the tensor-program manifests).

    .venv/bin/python scripts/policy.py [kernel ...]   -> tests/baselines/policy-gfx950.json
"""
from __future__ import annotations

import json
import math
import sys
import tempfile
import time
from pathlib import Path

from agc import corpus
from agc.runtime import toolchain
from agc.runtime.timing import PROTOCOL_VERSION
from agc.session import Session
from agc.session.policy import optimize

OUT = corpus.BASELINES.with_name("policy-gfx950.json")
TENSOR = sorted((corpus.CORPUS_DIR.parent / "tensor").glob("*.json"))


def main(argv) -> int:
    paths = [corpus.CORPUS_DIR / f"{n}.json" for n in (argv or corpus.names())] + ([] if argv else TENSOR)
    out = json.loads(OUT.read_text()) if OUT.exists() and argv else {"kernels": {}}
    out.update(protocol=PROTOCOL_VERSION, toolchain=toolchain.identity(), baseline="amdclang -O3", recorded=time.strftime("%Y-%m-%d"))
    root = tempfile.mkdtemp(prefix="agc-policy-")
    for path in paths:
        s = Session.open(path, root)
        r = optimize(s)
        c = r["chosen"]
        out["kernels"][r["kernel"]] = {"chosen": c, "fallback": r["fallback"],
                                       "candidates": [{k: v for k, v in row.items() if k != "state"} for row in r["candidates"]]}
        sp = f"{c['speedup']:.3f}x {c['ci95']}" if c.get("ci95") else ("fallback" if r["fallback"] else f"{c.get('ms')} ms, no baseline")
        print(f"{r['kernel']:20s} {c['path']:12s} {c['how']:44s} {sp}", flush=True)
    ks = {n: k for n, k in out["kernels"].items() if k["chosen"].get("speedup")}
    sp = [k["chosen"]["speedup"] for k in ks.values()]
    no_mfma = [k["chosen"]["speedup"] for n, k in ks.items() if "gemm_mfma" not in k["chosen"]["how"]]
    out["summary"] = {"kernels": len(out["kernels"]), "with_baseline": len(sp), "wins": sum(not k["fallback"] for k in ks.values()),
                      "fallbacks": sum(k["fallback"] for k in ks.values()),
                      "geomean": round(math.exp(sum(map(math.log, sp)) / len(sp)), 3),
                      "geomean_without_mfma_gemm": round(math.exp(sum(map(math.log, no_mfma)) / len(no_mfma)), 3)}
    out["kernels"] = dict(sorted(out["kernels"].items()))
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    print(out["summary"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
