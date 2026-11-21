#!/usr/bin/env python
"""Kernel fusion: two corpus kernels in a row against the one kernel generated from their fused tensor program.

    .venv/bin/python scripts/fusion.py [FIRST:SECOND ...]

For each pair the second kernel consumes the first one's output `y` as its input `x` (`agc.tair.fuse`).
Sequential time: the fastest verified kernel for each stage (amdclang's build or any parameter of the
generator template), each timed alone at the same number of elements, added up. Fused time: the fastest
parameter of the template on the fused program, after the static checks and the full battery against the
fused program evaluated in float64. Every timing is the median over several processes (each a fresh
allocation of the tensors), each the protocol's median of single launches with flushed caches. The two sides
are different launches on different tensors, so this is a ratio of medians, not a paired timing.
"""
from __future__ import annotations

import itertools
import json
import math
import sys
import time

import numpy as np

from agc import corpus, gen
from agc.manifest import Manifest, eval_expr
from agc.mir import check
from agc.runtime import harness, toolchain
from agc.runtime.timing import PROTOCOL_VERSION, TimingProtocol
from agc.tair.fuse import fuse_manifests

OUT = corpus.BASELINES.with_name("fusion-gfx950.json")
PAIRS = [("rmsnorm", "gelu"), ("layernorm", "gelu"), ("gelu", "cast_bf16")]
RUNS = 3


def timed(m: Manifest, hsaco: bytes, launch, symbols) -> dict | None:
    """Median over RUNS processes with flushed caches (`ms`), and with the caches as the previous launch of the
    same kernel left them (`warm_ms`): under `flush` every launch also evicts what the harness wrote."""
    out = {}
    for key, cache in (("ms", "flush"), ("warm_ms", "warm")):
        ms = []
        for _ in range(RUNS):
            r = harness.bench(m, hsaco, launch=launch, symbols=symbols, priority="batch", protocol=TimingProtocol(cache=cache))
            if not r.get("ok"):
                return None
            ms.append(r["timing"]["median_ms"])
        out[key] = round(float(np.median(ms)), 5)
        out["range_" + key] = [round(min(ms), 5), round(max(ms), 5)]
    return out


def variants(m: Manifest, symbols, battery: bool) -> list[dict]:
    """Every verified build of a manifest with its time: amdclang's (when there is a source) and the template's."""
    rows = []
    if m.source is not None:
        t = timed(m, harness.reference_build(m).hsaco, None, symbols)
        if t:
            rows.append({"how": "amdclang -O3", **t})
    for template in gen.applicable(m):
        space = gen.TEMPLATES[template]["params"]
        for values in itertools.product(*space.values()):
            params = dict(zip(space, values))
            c = gen.generate(m, template, params)
            st = check.static_check(c.module, strict=True)
            if not st["ok"]:
                continue
            if battery:
                ck = harness.check(m, st["built"].hsaco, launch=c.launch, priority="batch")
                if not ck.get("ok"):
                    rows.append({"how": f"{template}{params}", "battery": "FAILED"})
                    continue
            t = timed(m, st["built"].hsaco, c.launch, symbols)
            if t:
                rows.append({"how": f"{template}({', '.join(f'{k}={v}' for k, v in params.items())})", **t,
                             **({"battery": f"{ck.get('cases_run')}/{ck.get('cases_total')}"} if battery else {})})
    return rows


def run(a: str, b: str) -> dict:
    ma, mb = corpus.load(a), corpus.load(b)
    mf = Manifest.from_dict(fuse_manifests(ma, mb, {"x": "y"}), ma.path)
    sym = ma.timing_symbols()
    elements = math.prod(eval_expr(e, sym) for e in ma.outputs()[0].shape)
    bsym = {k: elements for k in mb.timing_symbols()}        # the second stage alone, on as many elements (1-D kernels)
    if len(mb.timing_symbols()) != 1 and mb.timing_symbols() != sym:
        raise SystemExit(f"{b}: cannot size the second stage for {elements} elements")
    first, second, fused = variants(ma, sym, False), variants(mb, bsym if len(bsym) == 1 else sym, False), variants(mf, sym, True)
    best = lambda rows: min((r for r in rows if "ms" in r), key=lambda r: r["ms"], default=None)
    f1, f2, ff = best(first), best(second), best(fused)
    if ff is None:
        print(f"{a} -> {b}: no fused variant passed the battery", flush=True)
        return {"program": mf.program.text, "elements": elements, "first": first, "second": second, "fused": fused, "speedup": None}
    seq = f1["ms"] + f2["ms"]
    w = lambda rows: min(r["warm_ms"] for r in rows if "warm_ms" in r)
    warm = (w(first) + w(second)) / w(fused)
    out = {"program": mf.program.text, "elements": elements, "first": first, "second": second, "fused": fused,
           "sequential_ms": round(seq, 5), "fused_ms": ff["ms"], "speedup": round(seq / ff["ms"], 3), "warm_speedup": round(warm, 3),
           "warm_ms": {"first": w(first), "second": w(second), "fused": w(fused)},
           "speedup_range": [round((f1["range_ms"][0] + f2["range_ms"][0]) / ff["range_ms"][1], 3),
                             round((f1["range_ms"][1] + f2["range_ms"][1]) / ff["range_ms"][0], 3)],
           "best": {"first": f1["how"], "second": f2["how"], "fused": ff["how"]}}
    print(f"{a} -> {b}: sequential {seq:.4f} ms ({f1['how']} {f1['ms']:.4f} + {f2['how']} {f2['ms']:.4f}), "
          f"fused {ff['ms']:.4f} ms ({ff['how']}): {out['speedup']:.3f}x {out['speedup_range']}; warm caches {warm:.3f}x "
          f"({w(first):.4f} + {w(second):.4f} against {w(fused):.4f} ms)", flush=True)
    return out


def main(argv) -> int:
    pairs = [tuple(x.split(":")) for x in argv] or PAIRS
    rec = json.loads(OUT.read_text()) if OUT.exists() else {"pairs": {}}
    rec.update(what="two kernels in a row (the fastest verified build of each, timed alone, added up) against the kernel generated "
                    "from their fused tensor program; ratios of medians over several allocations, not paired timings; `speedup` with caches flushed before every launch, "
                    "`warm_speedup` with the caches as the previous launch left them",
               protocol=PROTOCOL_VERSION, toolchain=toolchain.identity(), recorded=time.strftime("%Y-%m-%d"), runs=RUNS)
    for a, b in pairs:
        rec["pairs"][f"{a}:{b}"] = run(a, b)
        OUT.write_text(json.dumps(rec, indent=1) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
