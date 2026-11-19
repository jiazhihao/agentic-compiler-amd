#!/usr/bin/env python
"""bf16 GEMM (C = A @ B^T, f32 result): every variant of the MFMA template on the full battery, then
timed at three shapes next to amdclang's build of the HIP kernel and hipBLASLt.

    .venv/bin/python scripts/gemm.py   -> tests/baselines/gemm-gfx950.json
"""
from __future__ import annotations

import itertools
import json
import sys
import time

from agc import corpus, gen
from agc.mir import check
from agc.runtime import baselines, harness, toolchain
from agc.runtime.timing import PROTOCOL_VERSION

OUT = corpus.BASELINES.with_name("gemm-gfx950.json")
SHAPES = {"square": (4096, 4096, 4096), "wide": (2048, 8192, 4096), "tall": (8192, 2048, 4096), "small": (2048, 2048, 2048)}


def main() -> int:
    m = corpus.load("gemm_bf16")
    ref = harness.reference_build(m).hsaco
    space = gen.TEMPLATES["gemm_mfma"]["params"]
    variants = []
    for values in itertools.product(*space.values()):
        params = dict(zip(space, values))
        c = gen.generate(m, "gemm_mfma", params)
        st = check.static_check(c.module, strict=True)
        k = c.module.kernel()
        ck = harness.check(m, st["built"].hsaco, launch=c.launch, priority="batch") if st["ok"] else {"ok": False}
        variants.append({"params": params, "static": st["ok"], "battery": f"{ck.get('cases_run')}/{ck.get('cases_total')}" if ck["ok"] else "FAILED",
                         "vgprs": k.metadata[".vgpr_count"], "agprs": k.metadata[".agpr_count"],
                         "instructions": sum(1 for _ in k.insts()), "_c": c, "_h": st.get("built")})
        print(params, variants[-1]["battery"], flush=True)
    out = {"protocol": PROTOCOL_VERSION, "toolchain": toolchain.identity(), "recorded": time.strftime("%Y-%m-%d"),
           "operation": "C[M,N] = A[M,K] @ B[N,K]^T, bf16 inputs, f32 result", "shapes": {}}
    for name, (M, N, K) in SHAPES.items():
        sym = {"M": M, "N": N, "K": K}
        row = {"M": M, "N": N, "K": K, "agc": []}
        lib = baselines.hipblaslt_gemm(M, N, K, priority="batch")
        row["hipblaslt_ms"] = round(lib["median_ms"], 5) if lib.get("ok") else None
        a = harness.bench(m, ref, symbols=sym, priority="batch")
        row["amdclang_ms"] = round(a["timing"]["median_ms"], 4)
        for v in variants:
            if v["battery"] == "FAILED":
                continue
            p = harness.paired(m, ref, v["_h"].hsaco, candidate_launch=v["_c"].launch, symbols=sym, priority="batch")
            ms = p["candidate"]["median_ms"]
            row["agc"].append({"params": v["params"], "ms": round(ms, 5), "tflops": round(2 * M * N * K / ms / 1e9, 1),
                               "vs_amdclang": round(p["speedup"], 1), "vs_amdclang_ci95": [round(x, 1) for x in p["speedup_ci95"]],
                               "outcome": p["outcome"], "hipblaslt_ratio": round(ms / lib["median_ms"], 3) if lib.get("ok") else None})
        best = min(row["agc"], key=lambda r: r["ms"])
        row["best"] = best
        out["shapes"][name] = row
        print(f"{name:7s} {M}x{N}x{K}: amdclang {row['amdclang_ms']} ms, hipBLASLt {row['hipblaslt_ms']} ms, agc {best['ms']} ms "
              f"{best['params']} = {best['vs_amdclang']}x amdclang, {best['hipblaslt_ratio']}x hipBLASLt's time, {best['tflops']} TFLOPS", flush=True)
    out["variants"] = [{k: v for k, v in x.items() if not k.startswith("_")} for x in variants]
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
