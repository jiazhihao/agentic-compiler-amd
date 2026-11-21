#!/usr/bin/env python
"""agc's own lowering from HIP (roadmap phase 2) on every kernel that has a HIP source.

    .venv/bin/python scripts/own_path.py [--no-time] [kernel ...]   -> tests/baselines/own-gfx950.json
    .venv/bin/python scripts/own_path.py --decisions [kernel ...]   the loop and reduction decisions on the kernels that have them
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
        if e.kind in ("unsupported", "internal"):
            row["stage"] = "lower"
        return row
    except Exception as e:  # noqa: BLE001  (a crash of the lowering is a row of the table, not the end of the run)
        row.update(stage="lower", stopped="internal", reason=f"{type(e).__name__}: {e}"[:400])
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
    own = {p.stem: p for p in sorted((corpus.CORPUS_DIR.parent / "own").glob("*.json"))}     # the lowering's own test kernels
    for name, path in {**manifests(), **own}.items():
        m = Manifest.load(path)
        try:
            text = print_func(lower_hip(m.source, m.entry, flags=m.hip_flags, mcpu=m.arch))
        except FrontendError:
            continue
        (KIR / f"{name}.kir").write_text(text)
        n += 1
    print(f"{n} fixtures in {KIR}")
    return 0


LOOPS = (4, 8, 16)


def decisions(path: Path, root: str) -> dict | None:
    """The decisions that change a kernel's schedule, on one kernel: `loop.unroll` at each factor, and
    `reduce.form: dpp` alone and with the unrolling, each through the static check, the full battery, the
    differential check and a paired timing against amdclang -O3. Returns the best verified one and every
    attempt; None when the kernel has none of these decisions."""
    s = Session.open(path, root)
    try:
        base = s.lower()
    except SessionError:
        return None
    have = {e["decision"] for e in s.plan(base["id"])["decisions"]}
    loops = [{"loop.unroll": n} for n in LOOPS] if "loop.unroll" in have else []
    tries = list(loops)
    if "reduce.form" in have:
        tries += [{"reduce.form": "dpp"}] + [{"reduce.form": "dpp", **ov} for ov in loops]
    if not tries:
        return None
    rows = []
    for ov in tries:
        row = {"overrides": ov}
        try:
            sid = s.replan(base["id"], ov)["id"]
            ck = s.check(sid)
            if not ck["ok"]:
                row.update(outcome="battery", reason=json.dumps(ck.get("failures") or ck.get("error"))[:300])
            else:
                c = s.compare("ref", sid)
                row.update(outcome=c.get("outcome_b_vs_a"), speed_over_amdclang=c.get("speedup_b_over_a"), ci95=c.get("ci95"),
                           own_ms=c.get("b_ms"), bit_identical=bool(s.equivalent(sid, "ref").get("bit_identical")),
                           instructions=insts(s, sid))
        except SessionError as e:
            row.update(outcome="rejected", reason=f"{e.kind}: {e.message}"[:300])
        rows.append(row)
    wins = [r for r in rows if r.get("outcome") == "win"]
    return {"tried": rows, "best": max(wins, key=lambda r: r["ci95"][0]) if wins else None}


def main(argv) -> int:
    if "--fixtures" in argv:
        return fixtures()
    if "--decisions" in argv:
        names = [a for a in argv if not a.startswith("--")]
        out = json.loads(OUT.read_text())
        root = tempfile.mkdtemp(prefix="agc-own-")
        for name, path in manifests().items():
            k = out["kernels"].get(name)
            if (names and name not in names) or not k or k["stage"] != "battery":
                continue
            d = decisions(path, root)
            if d is None:
                k.pop("loop_decisions", None)
                k.pop("decisions_tried", None)
                continue
            k.pop("loop_decisions", None)
            k["decisions_tried"] = d
            b = d["best"]
            print(f"{name:26s} " + (f"{b['overrides']} {b['speed_over_amdclang']} {b['ci95']} bit-identical={b['bit_identical']}" if b
                                     else "no verified win: " + "; ".join(str(r.get('speed_over_amdclang') or r.get('reason'))[:60] for r in d["tried"])),
                  flush=True)
        OUT.write_text(json.dumps(out, indent=1) + "\n")
        return 0
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
