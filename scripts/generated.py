#!/usr/bin/env python
"""Compile every corpus kernel that has a tair program with every template parameter, verify each
on the full battery and pair it against amdclang's build of the HIP version.

    .venv/bin/python scripts/generated.py [kernel ...]   -> tests/baselines/generated-gfx950.json
"""
from __future__ import annotations

import itertools
import json
import math
import sys
import time

from agc import corpus, gen
from agc.mir import check
from agc.runtime import harness, toolchain
from agc.runtime.timing import PROTOCOL_VERSION

OUT = corpus.BASELINES.with_name("generated-gfx950.json")


def run(name: str) -> dict:
    m = corpus.load(name)
    ref = harness.reference_build(m).hsaco
    template = gen.applicable(m)[0]
    space = gen.TEMPLATES[template]["params"]
    rows = []
    for values in itertools.product(*space.values()):
        params = dict(zip(space, values))
        try:
            c = gen.generate(m, template, params)
        except gen.GenError:
            continue                                        # a combination the template does not have
        st = check.static_check(c.module, strict=True)
        row = {"params": params, "instructions": sum(1 for _ in c.module.kernel().insts()), "static": st["ok"]}
        if st["ok"]:
            ck = harness.check(m, st["built"].hsaco, launch=c.launch, priority="batch")
            row["battery"] = f"{ck.get('cases_run')}/{ck.get('cases_total')}" if ck.get("ok") else "FAILED"
            if ck.get("ok"):
                b = harness.paired(m, ref, st["built"].hsaco, candidate_launch=c.launch, priority="batch")
                row.update(outcome=b["outcome"], speedup=round(b["speedup"], 4), ci95=[round(x, 4) for x in b["speedup_ci95"]],
                           ms=round(b["candidate"]["median_ms"], 5), amdclang_ms=round(b["reference"]["median_ms"], 5))
        rows.append(row)
        print(f"{name:10s} {template:11s} {str(params):26s} {row.get('battery', 'static failed'):8s} "
              f"{row.get('outcome', '-'):6s} {row.get('speedup', 0):.3f} {row.get('ci95', '')}", flush=True)
    ok = [r for r in rows if "speedup" in r]
    best = max(ok, key=lambda r: r["ci95"][0]) if ok else None
    return {"template": template, "variants": rows, "best": best}


def main(argv) -> int:
    names = argv or [n for n in corpus.names() if corpus.load(n).program]
    out = json.loads(OUT.read_text()) if OUT.exists() else {"kernels": {}}
    out.update(protocol=PROTOCOL_VERSION, toolchain=toolchain.identity(), baseline="amdclang -O3", recorded=time.strftime("%Y-%m-%d"))
    for n in names:
        out["kernels"][n] = run(n)
    best = [k["best"]["speedup"] for k in out["kernels"].values() if k["best"]]
    default = []
    for n, k in out["kernels"].items():
        d = gen.TEMPLATES[k["template"]]["default"]
        default += [r["speedup"] for r in k["variants"] if r["params"] == d and "speedup" in r]
    out["geomean_best"] = round(math.exp(sum(map(math.log, best)) / len(best)), 4)
    out["geomean_default"] = round(math.exp(sum(map(math.log, default)) / len(default)), 4)
    out["kernels"] = dict(sorted(out["kernels"].items()))
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    print(f"geomean over {len(best)} kernels: best parameters {out['geomean_best']}, default parameters {out['geomean_default']}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
