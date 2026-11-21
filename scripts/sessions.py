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


def warm_note(c: dict) -> str:
    w = c.get("warm") or {}
    return f" (warm caches: {w['speedup']:.3f})" if w.get("speedup") else ""


def table() -> str:
    pol, rec = json.loads(POLICY.read_text())["kernels"], recipes()
    strong = json.loads(STRONG.read_text())["kernels"] if STRONG.exists() else {}
    rows = ["| kernel | library | amdclang -O3, shipped source (ms) | strongest amdclang build | its speedup over -O3 shipped | baseline ms "
            "| default policy over the baseline | agent session over the baseline (95% CI) | how | total over -O3 shipped |",
            "|---|---|---|---|---|---|---|---|---|---|"]
    gain, total, warm_gain = [], [], []
    for n, k in pol.items():
        st = strong.get(n, {})
        base = st.get("over_shipped_O3", 1.0)
        p = 1.0 if k["fallback"] else k["chosen"]["speedup"]
        r = rec.get(n)
        g = max(p, r["verified"]["speedup"] if r else 1.0)
        gain.append(g)
        w = (k["chosen"].get("warm") or {}) if not k["fallback"] else {}
        pw = p if not w else (w["speedup"] if w.get("outcome") == "win" else 1.0)     # with warm caches, where that was measured
        warm_gain.append(max(pw, r["verified"]["speedup"] if r else 1.0))
        tot = r.get("attribution", {}).get("over_shipped_O3") if r and r["verified"]["speedup"] >= p else None
        total.append(tot or base * g)
        cells = [f"`{n}`", k["library"], f"{st.get('amdclang_O3_ms', k['amdclang_ms']):.4f}", how_baseline(st.get("baseline")),
                 f"{base:.2f}" if st.get("baseline") else "", f"{k['amdclang_ms']:.4f}",
                 "fallback" if k["fallback"] else f"{p:.3f} `{k['chosen']['how']}`" + warm_note(k["chosen"])]
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
                 f"geomean of the agc gain {gm(gain):.3f} with fallbacks at 1.0; geomean over -O3 on the shipped source {gm(total):.3f}.",
             "", "Timings flush the caches before every launch. Results of `stream_loads` (non-temporal loads) depend on that: with the "
                 "caches as the previous launch left them (`warm caches`) they are mostly parity. Counting those results at their "
                 f"warm-cache value, {sum(g > 1 for g in warm_gain)} of {len(gain)} kernels have a gain and the geomean is {gm(warm_gain):.3f}."]
    return "\n".join(rows)


def comment(name: str) -> str:
    r = json.loads((Path(".agc") / "harness" / f"{name}.json").read_text())
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


def gain(name: str) -> float:
    """The verified agc gain recorded for a kernel (session recipe), 1.0 without one."""
    r = recipes().get(name)
    return r["verified"]["speedup"] if r else 1.0


def campaign(a) -> None:
    """Several sessions per kernel, one kernel after another: each session gets the kernel's analysis so far and
    continues from it. A kernel is done at the target, or when a session after the first adds less than 1 %."""
    import llmbench
    import strong_baseline
    log = lambda t: print(t, flush=True)
    for n in a.kernels:
        best = gain(n)
        for k in range(a.sessions):
            doc = agent.runner.ANALYSES / f"{n}.md"
            extra = ""
            if doc.exists():
                extra = (f"Earlier sessions' ISA-level analysis of this kernel is in `{doc.relative_to(agent.runner.REPO)}`: read it first. "
                         "Do not repeat what it measured. Take the opportunities it lists as untested, and ideas of a different kind "
                         f"from the ones it tried. The best verified gain so far is {best:.3f}x"
                         + (" (the recorded recipe; it is in list_states only if the baseline did not change: `bench/llm/sessions/"
                            f"{n}/best.s` is its text)." if best > 1 else "."))
            r = agent.run(BENCH / f"{n}.json", minutes=a.minutes, benches=a.benches, model=a.model, extra=extra, log=log)
            if r.get("baseline_candidate") and strong_baseline.promote(n):
                strong_baseline.run([n])
                agent.replay([n], log=log, update=True)
                llmbench.main([n])
            new = gain(n)
            log(f"{n}: session {k + 1}: {r['outcome']}; verified gain {best:.3f} -> {new:.3f}")
            if new >= a.target or (k >= 1 and new < best * 1.01):
                best = max(best, new)
                break
            best = max(best, new)
        log(f"{n}: done at {best:.3f}x after {k + 1} session(s)")


def main(argv) -> int:
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("run"); p.add_argument("kernels", nargs="+"); p.add_argument("--minutes", type=int, default=45)
    p.add_argument("--benches", type=int, default=30); p.add_argument("--model"); p.add_argument("--extra", default="")
    p = sub.add_parser("campaign"); p.add_argument("kernels", nargs="+"); p.add_argument("--minutes", type=int, default=30)
    p.add_argument("--benches", type=int, default=30); p.add_argument("--model"); p.add_argument("--sessions", type=int, default=3)
    p.add_argument("--target", type=float, default=1.5)
    sub.add_parser("table")
    p = sub.add_parser("comment"); p.add_argument("kernel")
    a = ap.parse_args(argv)
    if a.cmd == "table":
        print(table())
    elif a.cmd == "comment":
        print(comment(a.kernel))
    elif a.cmd == "campaign":
        campaign(a)
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
