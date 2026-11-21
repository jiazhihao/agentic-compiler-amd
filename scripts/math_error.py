#!/usr/bin/env python
"""Errors of the f32 math lowerings of agc's own path, measured on the device.

    .venv/bin/python scripts/math_error.py [--launches N]   -> tests/baselines/math-gfx950.json

For each function and each alternative of its decision: a kernel computes f(x) for x = the float whose bits
are `start + i * step`, so one launch of 2^20 lanes walks the whole range of float32 bit patterns at a stride
of 4096; further launches shift the start. The results are compared with the function evaluated in float64
and rounded to float32. Reported: the largest error in units in the last place and how many inputs were more
than half a unit off (not correctly rounded). This is a sample (N * 2^20 of the 2^32 inputs), not a proof.
"""
from __future__ import annotations

import json
import sys
import tempfile
import time
from pathlib import Path

import numpy as np

from agc import corpus
from agc.kir import parse_func
from agc.lower import lower_kir
from agc.manifest import Manifest
from agc.mir import check as mircheck, emit
from agc.runtime import harness, toolchain

OUT = corpus.BASELINES.with_name("math-gfx950.json")
N = 1 << 20
STEP = 1 << 12

KIR = """kir func probe(%y: ptr<f32>, %start: u32, %n: i32) {{
  %b: u32 = bid.x
  %d: u32 = bdim.x
  %g: u32 = mul %b, %d
  %t: u32 = tid.x
  %iu: u32 = add %g, %t
  %i: i32 = cast %iu
  %c: i1 = lt %i, %n
  if %c {{
    %k: u32 = mul %iu, {step}:u32
    %bits: u32 = add %start, %k
    %x: f32 = bitcast %bits
    %r: f32 = {op} %x
    %i64: i64 = cast %i
    %p: ptr<f32> = gep %y, %i64
    store %p, %r
  }}
}}
"""
MANIFEST = {"name": "probe", "entry": "probe", "source": "probe.hip", "shapes": {"N": N, "S": 0}, "dynamic": ["S"],
            "params": [{"name": "y", "kind": "tensor", "dtype": "f32", "shape": ["N"], "role": "out"},
                       {"name": "start", "kind": "scalar", "dtype": "u32", "value": "S"},
                       {"name": "n", "kind": "scalar", "dtype": "i32", "value": "N"}],
            "launch": {"grid": ["cdiv(N, 256)"], "block": [256]},
            "reference": {"kind": "python", "file": "probe_ref.py", "function": "probe"}}      # never evaluated: `run` returns raw outputs
# function -> (kir operation, the decision and its alternatives, the float64 reference, the inputs it is defined on)
CASES = {
    "exp": ("exp", "math.exp", ["exact", "hw"], np.exp, lambda x: np.isfinite(x)),
    "tanh": ("tanh", "math.tanh", ["exact"], np.tanh, lambda x: np.isfinite(x)),
    "sqrt": ("sqrt", "math.sqrt", ["exact", "hw"], np.sqrt, lambda x: np.isfinite(x) & (x >= 0)),
    "rcp": ("rcp", None, [None], lambda x: 1.0 / x, lambda x: np.isfinite(x) & (x != 0)),
}


def ulps(got: np.ndarray, x: np.ndarray, ref) -> np.ndarray:
    """|got - f(x)| in units in the last place of the correctly rounded result."""
    with np.errstate(all="ignore"):
        exact = ref(x.astype(np.float64))
        rounded = exact.astype(np.float32)
        unit = np.spacing(np.abs(rounded)).astype(np.float64)
        err = np.abs(got.astype(np.float64) - exact) / unit
    same = (got == rounded) | (np.isnan(got) & np.isnan(rounded))
    err = np.where(same | ~np.isfinite(rounded) | ~np.isfinite(got), np.where(same, 0.0, np.inf), err)
    # results in the subnormal range and overflow to infinity are not graded
    return np.where((np.abs(rounded) < np.finfo(np.float32).tiny) | ~np.isfinite(rounded), 0.0, err)


def main(argv) -> int:
    launches = int(argv[argv.index("--launches") + 1]) if "--launches" in argv else 4
    out = {"what": "sampled errors of agc's f32 math lowerings on the device, in units in the last place",
           "toolchain": toolchain.identity(), "recorded": time.strftime("%Y-%m-%d"), "inputs_per_launch": N,
           "launches": launches, "functions": {}}
    with tempfile.TemporaryDirectory() as d:
        mp = Path(d) / "probe.json"
        mp.write_text(json.dumps(MANIFEST))
        (Path(d) / "probe_ref.py").write_text("def probe(start, n):\n    raise NotImplementedError\n")
        (Path(d) / "probe.hip").write_text("// the kernel is built from kir text by scripts/math_error.py; this file is never compiled\n")
        m = Manifest.load(mp)
        for name, (op, decision, alts, ref, domain) in CASES.items():
            for alt in alts:
                r = lower_kir(parse_func(KIR.format(op=op, step=STEP)), {decision: alt} if alt else None)
                st = mircheck.static_check(r.module, strict=True)
                assert st["ok"], st["findings"][:2]
                hsaco = emit.build(r.module, check=False).hsaco
                worst, off, graded, worst_normal = 0.0, 0, 0, 0.0
                for k in range(launches):
                    start = (k * 977) % STEP
                    res = harness.run(m, hsaco, symbols={"N": N, "S": start}, root=Path(d))
                    if not res.get("ok"):
                        raise SystemExit(f"{name}: {res.get('error')}")
                    got = res["outputs"]["y"]
                    x = (np.uint32(start) + np.arange(N, dtype=np.uint32) * np.uint32(STEP)).view(np.float32)
                    ok = domain(x)
                    e = ulps(got[ok], x[ok], ref)
                    normal = np.abs(x[ok]) >= np.float32(2.0 ** -96)      # operands the machine does not treat as denormal
                    fin = np.isfinite(e)
                    worst_normal = max(worst_normal, float(e[fin & normal].max(initial=0.0)))
                    e = e[fin]
                    worst, off, graded = max(worst, float(e.max(initial=0.0))), off + int((e > 0.5).sum()), graded + int(e.size)
                key = f"{name}/{alt}" if alt else name
                out["functions"][key] = {"max_ulp": round(worst, 3), "max_ulp_operands_above_2^-96": round(worst_normal, 3),
                                         "not_correctly_rounded": off, "inputs": graded,
                                         "instructions": sum(len(b.insts) for b in r.module.kernels[0].blocks)}
                print(f"{key:14s} max {worst:12.3f} ulp ({worst_normal:.3f} for operands above 2^-96), {off} of {graded} not "
                      "correctly rounded", flush=True)
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
