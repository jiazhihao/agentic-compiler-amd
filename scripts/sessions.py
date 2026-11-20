#!/usr/bin/env python
"""Per-kernel agent sessions on the LLM benchmark (`agc.agent`).

    .venv/bin/python scripts/sessions.py run KERNEL [...] [--minutes N] [--model M]   sessions, one kernel after another
    .venv/bin/python scripts/sessions.py table                                        Markdown: default policy and session result per kernel
    .venv/bin/python scripts/sessions.py comment KERNEL                               Markdown of the last session (for the kernel's issue)
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

from agc import agent, corpus
from agc.session import Session

BENCH = Path(__file__).resolve().parent.parent / "bench" / "llm"
POLICY = corpus.BASELINES.with_name("llm-gfx950.json")
FLAGS = corpus.BASELINES.with_name("llm-flags-gfx950.json")


def recipes() -> dict:
    return {d.name: json.loads((d / "recipe.json").read_text()) for d in sorted(agent.RECIPES.glob("*")) if (d / "recipe.json").exists()}


def table() -> str:
    pol, rec = json.loads(POLICY.read_text())["kernels"], recipes()
    flags = json.loads(FLAGS.read_text())["kernels"] if FLAGS.exists() else {}
    rows = ["| kernel | library | amdclang -O3 ms | amdclang -O3 -ffast-math | default policy | agent session (95% CI) | amdclang on the rewritten source | machine-level gain | how |",
            "|---|---|---|---|---|---|---|---|---|"]
    best = []
    for n, k in pol.items():
        p = "fallback" if k["fallback"] else f"{k['chosen']['speedup']:.3f}"
        fm = flags.get(n, {}).get("-ffast-math")
        fm = "same code" if fm == "identical code" else f"{fm[1]:.3f}" if isinstance(fm, list) else "fails" if fm else ""
        r = rec.get(n)
        sp = max(1.0 if k["fallback"] else k["chosen"]["speedup"], r["verified"]["speedup"] if r else 1.0)
        best.append(sp)
        if r:
            v = r["verified"]
            how = " + ".join(r["path"]) + ("" if r["launch"] is None else ", own launch")
            a = r.get("attribution", {})
            src = a.get("amdclang_on_rewritten_source")
            rows.append(f"| `{n}` | {k['library']} | {k['amdclang_ms']:.4f} | {fm} | {p} | **{v['speedup']:.3f}** ({v['speedup_ci95'][0]:.3f} to {v['speedup_ci95'][1]:.3f}) "
                        f"| {'' if src is None else f'{src:.3f}'} | {'' if a.get('machine_level_gain') is None else f'{a['machine_level_gain']:.2f}'} | {how} |")
        else:
            rows.append(f"| `{n}` | {k['library']} | {k['amdclang_ms']:.4f} | {fm} | {p} | | | | |")
    wins = sum(s > 1 for s in best)
    rows += ["", "All speedups are over amdclang -O3 on the benchmark source as shipped. \"amdclang on the rewritten source\" is the part of a "
                 "session's speedup that amdclang itself delivers once the source is restructured; \"machine-level gain\" is what agc's own "
                 "level adds on top (1.00: none). The -ffast-math column is the unmodified source with that flag.",
             "", f"{wins} of {len(best)} kernels faster than amdclang (policy or session); {len(best) - wins} fallbacks; "
                 f"geomean of the best verified result {math.exp(sum(map(math.log, best)) / len(best)):.3f} with fallbacks at 1.0."]
    return "\n".join(rows)


def comment(name: str) -> str:
    s = Session.open(BENCH / f"{name}.json", ".agc")
    r = json.loads((s.store.root / "harness-result.json").read_text())
    L = [f"**Session result: {r['outcome']}**" + (f" {r['speedup']:.3f}x, 95% CI {r['ci95'][0]:.3f} to {r['ci95'][1]:.3f} "
                                                  f"(harness verification: static check, full battery, two valid paired timings)" if r["outcome"] == "win" else f" ({r.get('why')})"), ""]
    a = r.get("agent", {})
    if a.get("seconds"):
        L += [f"Agent: {a['seconds']} s, {a.get('turns')} turns.", ""]
    if r.get("summary"):
        L += ["What the agent reports (its own numbers, not the harness's):", "", "> " + r["summary"].replace("\n", "\n> "), ""]
    if r.get("tried"):
        L += ["| tried | outcome | speedup |", "|---|---|---|"]
        L += [f"| {str(t.get('what', '')).replace('|', '/')} | {t.get('outcome', '')} | {t.get('speedup', '')} |" for t in r["tried"] if isinstance(t, dict)]
        L.append("")
    if r.get("friction"):
        L += ["Friction reported:", ""] + [f"- {f}" for f in r["friction"]] + [""]
    if r.get("lessons"):
        L += ["Lessons reported:", ""] + [f"- {f}" for f in r["lessons"]]
    return "\n".join(L)


def main(argv) -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("run"); p.add_argument("kernels", nargs="+"); p.add_argument("--minutes", type=int, default=45)
    p.add_argument("--benches", type=int, default=30); p.add_argument("--model"); p.add_argument("--extra", default="")
    sub.add_parser("table")
    p = sub.add_parser("comment"); p.add_argument("kernel")
    a = ap.parse_args(argv)
    if a.cmd == "table":
        print(table())
    elif a.cmd == "comment":
        print(comment(a.kernel))
    else:
        for n in a.kernels:
            agent.run(BENCH / f"{n}.json", minutes=a.minutes, benches=a.benches, model=a.model, extra=a.extra,
                      log=lambda t: print(t, flush=True))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
