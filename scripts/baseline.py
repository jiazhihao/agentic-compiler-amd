#!/usr/bin/env python
"""Record the amdclang baseline of every corpus kernel: battery verdict, timing at the manifest's
bench shapes, resources and occupancy, and an A/A control.

    .venv/bin/python scripts/baseline.py [kernel ...]      -> tests/baselines/amdclang-gfx950.json
"""
from __future__ import annotations

import json
import sys
import time

from agc import corpus
from agc.arch.model import load as load_arch
from agc.runtime import harness, toolchain
from agc.runtime.timing import PROTOCOL_VERSION


def baseline(name: str) -> dict:
    m = corpus.load(name)
    arch = load_arch(m.arch)
    b = harness.reference_build(m)
    chk = harness.check(m, b.hsaco, priority="batch")
    if not chk["ok"]:
        raise SystemExit(f"{name}: battery failed: {json.dumps(chk.get('failures') or chk.get('error'))[:800]}")
    r = harness.bench(m, b.hsaco, priority="batch")
    if not r["ok"]:
        raise SystemExit(f"{name}: bench failed: {json.dumps(r)[:800]}")
    aa = harness.paired(m, b.hsaco, b.hsaco, priority="batch", device=r["gpu"]["device"])
    res = r["resources"]
    block = m.resolve(m.timing_symbols()).block
    occ = arch.occupancy(arch_vgprs=res["vgprs"], agprs=res["agprs"], sgprs=res["sgprs"], lds_bytes=res["lds_bytes"],
                         workgroup_size=block[0] * block[1] * block[2])
    t = r["timing"]
    return {"symbols": m.timing_symbols(), "battery_cases": chk["cases_run"],
            "median_ms": round(t["median_ms"], 5), "ci95_median_ms": [round(x, 5) for x in t["ci95_median_ms"]],
            "n": t["n"], "converged": r["converged"], "resources": res,
            "waves_per_simd": occ["waves_per_simd"], "occupancy_limiter": occ["limiter"],
            "instructions": sum(1 for l in b.asm.split(".amdhsa_kernel")[0].splitlines()
                                if l.startswith("\t") and not l.lstrip().startswith((".", ";"))),
            "aa_speedup": round(aa["speedup"], 4), "aa_ci95": [round(x, 4) for x in aa["speedup_ci95"]],
            "device": r["gpu"]["device"], "clock_levels": r["clocks"]["levels"]}


def main(argv) -> int:
    names = argv or corpus.names()
    out = json.loads(corpus.BASELINES.read_text()) if corpus.BASELINES.exists() else {}
    out.update({"protocol": PROTOCOL_VERSION, "toolchain": toolchain.identity(), "compiler": "amdclang -O3",
                "recorded": time.strftime("%Y-%m-%d")})
    kernels = out.setdefault("kernels", {})
    for name in names:
        kernels[name] = baseline(name)
        k = kernels[name]
        print(f"{name:12s} {k['median_ms']:9.4f} ms  A/A {k['aa_speedup']:.4f} {k['aa_ci95']}  "
              f"v{k['resources']['vgprs']} s{k['resources']['sgprs']} lds{k['resources']['lds_bytes']} "
              f"occ {k['waves_per_simd']} insts {k['instructions']}", flush=True)
    out["kernels"] = dict(sorted(kernels.items()))
    corpus.BASELINES.write_text(json.dumps(out, indent=1) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
