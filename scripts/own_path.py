#!/usr/bin/env python
"""agc's own lowering from HIP (roadmap phase 2) on every kernel that has a HIP source.

    .venv/bin/python scripts/own_path.py [--no-time] [kernel ...]   -> tests/baselines/own-gfx950.json
    .venv/bin/python scripts/own_path.py --fixtures                 -> tests/kir/<kernel>.kir (the frontend's output)

Per kernel: how far it gets (frontend, lowered, static check, battery) with the reason when it stops,
and for those that pass: whether the outputs are bit-identical to amdclang -O3's on every battery case,
the instruction count against amdclang's, and the paired speed over amdclang -O3 on the source as shipped
(below 1.0 means the own path is slower: reported as it is). The default plan only: no decision is changed.
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
from agc.session import Session, SessionError

OUT = corpus.BASELINES.with_name("own-gfx950.json")
LLM = Path(__file__).resolve().parent.parent / "bench" / "llm"


def manifests() -> dict[str, Path]:
    out = {}
    for p in sorted(corpus.CORPUS_DIR.glob("*.json")) + sorted(LLM.glob("*.json")):
        if json.loads(p.read_text()).get("source"):
            out[p.stem] = p
    return out


def insts(s: Session, ref: str) -> int:
    return sum(len(b.insts) for b in s._kernel(s.module(ref)).blocks)


def one(path: Path, root: str, timing: bool) -> dict:
    row: dict = {"stage": "open"}
    try:
        s = Session.open(path, root)
        row["stage"] = "frontend"
        st = s.lower()
    except SessionError as e:
        row.update(stopped=e.kind, reason=e.message[:400])
        if e.kind == "unsupported":
            row["stage"] = "lower"
        return row
    sid = st["id"]
    row.update(stage="lowered", instructions=insts(s, sid), amdclang_instructions=insts(s, "ref"),
               decisions=[f"{e['site']}.{e['decision']}" for e in s.plan(sid)["decisions"]])
    sc = s.static_check(sid)
    if not sc["ok"]:
        row.update(stopped="static", reason=json.dumps(sc["errors"][:2])[:400])
        return row
    row["stage"] = "static"
    try:
        ck = s.check(sid)
    except SessionError as e:
        row.update(stopped=e.kind, reason=e.message[:400])
        return row
    row["battery"] = f"{ck.get('cases_run')}/{ck.get('cases_total')}"
    if not ck["ok"]:
        row.update(stopped="battery", reason=json.dumps(ck.get("failures") or ck.get("error"))[:400])
        return row
    row["stage"] = "battery"
    eq = s.equivalent(sid, "ref")
    row["bit_identical"] = bool(eq.get("bit_identical"))
    if not eq.get("bit_identical"):
        row["max_rel_err"] = eq.get("max_rel_err")
    if timing:
        c = s.compare("ref", sid)
        if c.get("ok"):
            row.update(speed_over_amdclang=c["speedup_b_over_a"], ci95=c["ci95"], amdclang_ms=c["a_ms"], own_ms=c["b_ms"],
                       outcome=c["outcome_b_vs_a"])
        else:
            row["timing_error"] = str(c.get("error"))[:200]
    return row


KIR = corpus.CORPUS_DIR.parent / "kir"


def fixtures() -> int:
    """The frontend's `kir` of every kernel it accepts, as text: what the CPU tests lower without Clang."""
    from agc.frontend import FrontendError, lower_hip
    from agc.kir import print_func
    from agc.manifest import Manifest
    KIR.mkdir(exist_ok=True)
    n = 0
    for name, path in manifests().items():
        m = Manifest.load(path)
        try:
            text = print_func(lower_hip(m.source, m.entry, flags=m.hip_flags, mcpu=m.arch))
        except FrontendError:
            continue
        (KIR / f"{name}.kir").write_text(text)
        n += 1
    print(f"{n} fixtures in {KIR}")
    return 0


def main(argv) -> int:
    if "--fixtures" in argv:
        return fixtures()
    timing = "--no-time" not in argv
    names = [a for a in argv if not a.startswith("--")]
    every = manifests()
    todo = {n: every[n] for n in names} if names else every
    out = json.loads(OUT.read_text()) if OUT.exists() and names else {"kernels": {}}
    out.update(protocol=PROTOCOL_VERSION, toolchain=toolchain.identity(), recorded=time.strftime("%Y-%m-%d"),
               what="agc's own lowering from HIP (default plan) against amdclang -O3 on the source as shipped")
    root = tempfile.mkdtemp(prefix="agc-own-")
    for name, path in todo.items():
        row = one(path, root, timing)
        out["kernels"][name] = row
        tail = (f"{row.get('speed_over_amdclang', '-')} {row.get('ci95', '')} bit-identical={row.get('bit_identical')} "
                f"insts {row.get('instructions')}/{row.get('amdclang_instructions')}") if row["stage"] == "battery" else \
            f"stopped: {row.get('stopped')}: {row.get('reason', '')[:110]}"
        print(f"{name:26s} {row['stage']:9s} {tail}", flush=True)
    ks = out["kernels"] = dict(sorted(out["kernels"].items()))
    passed = {n: k for n, k in ks.items() if k["stage"] == "battery"}
    sp = [k["speed_over_amdclang"] for k in passed.values() if k.get("speed_over_amdclang")]
    out["summary"] = {"kernels": len(ks), "frontend_ok": sum(k["stage"] not in ("open", "frontend") for k in ks.values()),
                      "battery_ok": len(passed), "bit_identical": sum(bool(k.get("bit_identical")) for k in passed.values()),
                      "geomean_speed_over_amdclang": round(math.exp(sum(map(math.log, sp)) / len(sp)), 3) if sp else None,
                      "slowest": min(sp) if sp else None}
    OUT.write_text(json.dumps(out, indent=1) + "\n")
    print(out["summary"])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
