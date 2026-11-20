#!/usr/bin/env python
"""Per-kernel agent sessions on the LLM benchmark (`agc.agent`).

    .venv/bin/python scripts/sessions.py run KERNEL [...] [--minutes N] [--model M]   sessions, one kernel after another
    .venv/bin/python scripts/sessions.py table                                        Markdown: baseline, default policy and session result per kernel
    .venv/bin/python scripts/sessions.py comment KERNEL                               Markdown of the last session (for the kernel's issue)
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from agc import agent, corpus
from agc.session import Session

BENCH = Path(__file__).resolve().parent.parent / "bench" / "llm"
POLICY = corpus.BASELINES.with_name("llm-gfx950.json")
STRONG = corpus.BASELINES.with_name("llm-strong-gfx950.json")


def recipes() -> dict:
    return {d.name: json.loads((d / "recipe.json").read_text()) for d in sorted(agent.RECIPES.glob("*")) if (d / "recipe.json").exists()}


def how_baseline(b: dict | None) -> str:
    if not b:
        return "-O3, source as shipped"
    return " + ".join(x for x in ("restructured source" if b.get("source") else "", " ".join(b.get("flags", [])),
                                  "own launch" if b.get("launch") else "") if x)


def table() -> str:
    pol, rec = json.loads(POLICY.read_text())["kernels"], recipes()
    strong = json.loads(STRONG.read_text())["kernels"] if STRONG.exists() else {}
    rows = ["| kernel | library | amdclang -O3, shipped source (ms) | strongest amdclang build | its speedup over -O3 shipped | baseline ms "
            "| default policy over the baseline | agent session over the baseline (95% CI) | how | total over -O3 shipped |",
            "|---|---|---|---|---|---|---|---|---|---|"]
    gain, total = [], []
    for n, k in pol.items():
        st = strong.get(n, {})
        base = st.get("over_shipped_O3", 1.0)
        p = 1.0 if k["fallback"] else k["chosen"]["speedup"]
        r = rec.get(n)
        g = max(p, r["verified"]["speedup"] if r else 1.0)
        gain.append(g)
        tot = r.get("attribution", {}).get("over_shipped_O3") if r and r["verified"]["speedup"] >= p else None
        total.append(tot or base * g)
        cells = [f"`{n}`", k["library"], f"{st.get('amdclang_O3_ms', k['amdclang_ms']):.4f}", how_baseline(st.get("baseline")),
                 f"{base:.2f}" if st.get("baseline") else "", f"{k['amdclang_ms']:.4f}",
                 "fallback" if k["fallback"] else f"{p:.3f} `{k['chosen']['how']}`"]
        if r:
            v = r["verified"]
            cells += [f"**{v['speedup']:.3f}** ({v['speedup_ci95'][0]:.3f} to {v['speedup_ci95'][1]:.3f})",
                      " + ".join(x for x in r["path"] if x not in ("adopt",)) or "recorded recipe"]
        else:
            cells += ["", ""]
        cells.append(f"{total[-1]:.2f}")
        rows.append("| " + " | ".join(cells) + " |")
    gm = lambda xs: math.exp(sum(map(math.log, xs)) / len(xs))
    wins = sum(g > 1 for g in gain)
    rows += ["", "The baseline is the strongest amdclang build found per kernel (`scripts/strong_baseline.py`): the source as shipped or "
                 "a restructured source, with or without `-ffast-math`, with its own launch where that is faster; all of it is amdclang's "
                 "code. The policy and session columns are what agc adds on top of that build (machine IR passes and edits), verified by "
                 "the full battery and paired timings. The last column is for orientation: the best verified agc state, or else the "
                 "baseline, over amdclang -O3 on the source as shipped.",
             "", f"{wins} of {len(gain)} kernels have a verified agc gain over the strongest amdclang build; {len(gain) - wins} fallbacks; "
                 f"geomean of the agc gain {gm(gain):.3f} with fallbacks at 1.0; geomean over -O3 on the shipped source {gm(total):.3f}."]
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
        import llmbench
        import strong_baseline
        for n in a.kernels:
            r = agent.run(BENCH / f"{n}.json", minutes=a.minutes, benches=a.benches, model=a.model, extra=a.extra,
                          log=lambda t: print(t, flush=True))
            if r.get("baseline_candidate") and strong_baseline.promote(n):
                # the session's own source is a stronger amdclang build: it becomes the baseline, and the
                # policy record and the recipe (if any) are measured again against it
                strong_baseline.run([n])
                agent.replay([n], log=lambda t: print(t, flush=True), update=True)
                llmbench.main([n])
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
