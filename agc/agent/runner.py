from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

from ..session import Session, SessionError
from ..session.policy import optimize

REPO = Path(__file__).resolve().parents[2]
RECIPES = REPO / "bench" / "llm" / "sessions"
PROMPT = Path(__file__).with_name("prompt.md")
TOOLS = ["mcp__agc", "Read", "Grep", "Glob"]


def _prompt(s: Session, manifest: Path, minutes: int, benches: int, extra: str) -> str:
    ref = s.store.get_result(s.base_id, "bench") if s.base_id else None
    ms = f"{ref['candidate_ms']:.4f} ms" if ref and ref.get("candidate_ms") else "not timed yet"
    bl = s.manifest.baseline
    what = "amdclang -O3 on the source as shipped (state `ref`)" if not bl else (
        "amdclang on " + ("a restructured source" if bl.get("source") else "the shipped source")
        + (f" with {' '.join(bl['flags'])}" if bl.get("flags") else "") + (" and its own launch" if bl.get("launch") else "")
        + " (state `baseline`; `hip_source()` shows it; `ref` is -O3 on the source as shipped)")
    return PROMPT.read_text().format(name=s.manifest.name, manifest=manifest, ref_ms=ms, baseline=what,
                                     bench_shapes=json.dumps(s.manifest.timing_symbols()), minutes=minutes,
                                     benches=benches, extra=extra)


def agent(prompt: str, root: Path, log: Path, minutes: int, model: str | None = None) -> dict:
    """One headless Claude Code session with the agc MCP server. Returns {"ok", "seconds", "cost_usd", "turns"}."""
    exe = shutil.which("claude")
    if exe is None:
        raise RuntimeError("the `claude` CLI is not on PATH")
    cfg = log.with_suffix(".mcp.json")
    cfg.write_text(json.dumps({"mcpServers": {"agc": {"command": sys.executable, "args": ["-m", "agc.mcp.server"],
                                                      "env": {"AGC_ROOT": str(root.resolve())}}}}))
    cmd = [exe, "-p", prompt, "--mcp-config", str(cfg), "--strict-mcp-config", "--allowedTools", *TOOLS,
           "--tools", "Read,Grep,Glob", "--output-format", "stream-json", "--verbose", "--no-session-persistence"]
    if model:
        cmd += ["--model", model]
    t0 = time.time()
    out = {"ok": False, "cost_usd": None, "turns": None}
    with log.open("w") as f:
        p = subprocess.Popen(cmd, cwd=REPO, stdin=subprocess.DEVNULL, stdout=f, stderr=subprocess.STDOUT, env={**os.environ, "AGC_ROOT": str(root.resolve())})
        try:
            p.wait(timeout=60 * minutes * 2 + 600)          # the prompt's budget is the agent's; this is the hard stop
        except subprocess.TimeoutExpired:
            p.kill()
            out["error"] = "hard timeout"
    for line in log.read_text().splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "result":
            out.update(ok=not ev.get("is_error"), cost_usd=ev.get("total_cost_usd"), turns=ev.get("num_turns"),
                       final=str(ev.get("result", ""))[:2000])
    out["seconds"] = round(time.time() - t0)
    return out


MAX_CI_WIDTH = 0.04      # a paired timing whose 95 % CI is wider than this fraction of the speedup was disturbed (shared device): not a measurement
ATTEMPTS = 5
PAIRS = 240               # launches per code object in the harness's timings (the session default is 60)


def verify(s: Session, ref: str, against: str | None = None) -> dict:
    """The harness's own verdict on a state: static check and battery rerun, then paired timings until two
    are valid. A timing is valid when its CI is narrower than MAX_CI_WIDTH, whatever its direction. The
    state is a win when both valid timings are wins; the one with the lower bound is reported. Timings
    are against the session's baseline, or against the verified state `against`."""
    v = s.verify(ref, PAIRS)
    if not v.get("ok"):
        return v

    def timing() -> dict:
        if against is None:
            return s.bench(ref, PAIRS)
        c = s.compare(against, ref, PAIRS)
        return c if not c.get("ok") else {"ok": True, "outcome": c["outcome_b_vs_a"], "speedup": c["speedup_b_over_a"],
                                          "speedup_ci95": c["ci95"], "reference_ms": c["a_ms"], "candidate_ms": c["b_ms"]}
    valid, runs = [], []
    b = v
    for n in range(ATTEMPTS):
        if n or against is not None:
            b = timing()
            if not b.get("ok"):
                return {**v, "ok": False, "stage": "bench", "error": b.get("error")}
        lo, hi = b["speedup_ci95"]
        ok = (hi - lo) / b["speedup"] <= MAX_CI_WIDTH
        runs.append({"speedup": b["speedup"], "ci95": [lo, hi], "valid": ok})
        if ok:
            valid.append(b)
        if len(valid) == 2:
            break
    out = {**v, "runs": runs, "against": against or s.base_id}
    if len(valid) < 2:
        return {**out, "outcome": "disturbed"}
    worst = min(valid, key=lambda x: x["speedup_ci95"][0])
    out.update({k: worst.get(k) for k in ("speedup", "speedup_ci95", "reference_ms", "candidate_ms")})
    out["outcome"] = "win" if all(x["outcome"] == "win" for x in valid) else worst["outcome"] if worst["outcome"] != "win" else "unstable"
    return out


def own_source(s: Session, sid: str) -> dict | None:
    """When a state descends from the session's own `source` state (not the baseline): that amdclang build,
    as a baseline candidate ({"state", "file", "launch", "flags", "defines"})."""
    root = s.store.ancestry(sid)[0]
    if root.action.get("name") != "source" or root.id == s.base_id:
        return None
    a = root.action
    return {"state": root.id, "file": a["file"], "launch": a.get("launch_given") or a.get("launch"),
            "flags": [f for f in a.get("flags", []) if not f.startswith("-D")],
            "defines": dict(f[2:].split("=", 1) for f in a.get("flags", []) if f.startswith("-D"))}


def record(s: Session, sid: str, verdict: dict, report: dict, meta: dict, stronger: dict | None = None) -> Path:
    """Write the recipe of a verified win: the module text and launch, the gain over the strongest amdclang
    build (the verdict), and for orientation the total over amdclang -O3 on the source as shipped."""
    d = RECIPES / s.manifest.name
    d.mkdir(parents=True, exist_ok=True)
    ex = s.export(sid)
    (d / "best.s").write_text(ex["asm"])
    anc = s.store.ancestry(sid)
    attribution = {"levels": sorted({"source" if a.action.get("name") == "source" else "program" if a.action.get("name") == "generate"
                                     else "import" if a.action.get("name") == "import" else "mir" for a in anc}),
                   "baseline": s.manifest.baseline or "amdclang -O3 on the source as shipped",
                   "over_strongest_amdclang": verdict.get("speedup")}
    if stronger:
        attribution["own_source_over_baseline"] = stronger.get("speedup")
    if sid != s.ref_id and s.ref_id is not None:
        try:
            c = s.compare(s.ref_id, sid, PAIRS)
            if c.get("ok"):
                attribution["over_shipped_O3"] = c["speedup_b_over_a"]
        except SessionError as e:
            attribution["note"] = f"{e.kind}: {e.message}"[:200]
    recipe = {"kernel": s.manifest.name, "launch": ex["launch"], "strict": ex["strict"], "attribution": attribution,
              "path": [st["action"].get("name") for st in ex["trace"]],
              "verified": {**{k: verdict.get(k) for k in ("outcome", "speedup", "speedup_ci95", "reference_ms", "candidate_ms",
                                                          "cases", "protocol_version")}, "pairs": PAIRS, "runs": verdict.get("runs")},
              "summary": report.get("summary", ""), "tried": report.get("tried", []), "friction": report.get("friction", []),
              "lessons": report.get("lessons", []), "session": meta, "recorded": time.strftime("%Y-%m-%d")}
    (d / "recipe.json").write_text(json.dumps(recipe, indent=1) + "\n")
    return d


def run(manifest: str | Path, root: str | Path = ".agc", minutes: int = 45, benches: int = 30, model: str | None = None,
        policy: bool = True, extra: str = "", log=print, session: bool = True) -> dict:
    """One session on one kernel. Returns the harness's result (also written under the session's store).

    Outcomes: `win` (a verified state faster than the strongest amdclang build: the manifest's baseline and
    the session's own rewritten source, whichever is faster), `baseline` (the session's rewritten source is
    a faster amdclang build than the baseline, with no machine-level gain on top: a baseline candidate, not
    a win), `fallback`."""
    manifest, root = Path(manifest), Path(root)
    s = Session.open(manifest, root)
    name = s.manifest.name
    if s.base_id and s.store.get_result(s.base_id, "bench") is None:
        s.bench("baseline")                                  # the A/A control; also the baseline time for the prompt
    if policy and not any(st.action.get("name") == "apply" for st in s.store.all_states()):
        r = optimize(s)
        log(f"{name}: default policy: {'fallback' if r['fallback'] else r['chosen']['how'] + ' %.3fx' % r['chosen']['speedup']}")
    rep_path = s.store.root / "report.json"
    if session:
        if rep_path.exists():
            rep_path.rename(rep_path.with_name(f"report-{int(rep_path.stat().st_mtime)}.json"))
        logs = s.store.root / "agent"
        logs.mkdir(exist_ok=True)
        logf = logs / f"{time.strftime('%Y%m%d-%H%M%S')}.jsonl"
        meta = agent(_prompt(s, manifest, minutes, benches, extra), root, logf, minutes, model)
        meta["log"] = str(logf)
        log(f"{name}: agent finished in {meta['seconds']} s, {meta.get('turns')} turns, ${meta.get('cost_usd')}")
        s = Session.open(manifest, root)                      # the store as the agent left it
    else:                                                     # verify and record what the last session reported
        meta = {"resumed": True}
    report = json.loads(rep_path.read_text()) if rep_path.exists() else {}
    result = {"kernel": name, "agent": meta, "reported": bool(report), "friction": report.get("friction", []),
              "summary": report.get("summary", ""), "tried": report.get("tried", []), "lessons": report.get("lessons", [])}
    best = report.get("best")
    if best is None:                                          # no report: take the store's best measured win, if any
        b = s.best()
        best = b["id"] if b else None
    try:
        best = s.resolve(best) if best else None
    except SessionError:
        best = None
    old = RECIPES / name / "recipe.json"
    if best is None or best in (s.ref_id, s.base_id):
        result.update(outcome="fallback", why="the session named no state faster than the baseline")
    else:
        stronger = None
        try:
            own = own_source(s, best)
            if own:                                           # amdclang's part: the session's own source against the baseline
                rv = verify(s, own["state"])
                if rv.get("ok") and rv.get("outcome") == "win":
                    stronger = {**own, "speedup": rv["speedup"], "ci95": rv["speedup_ci95"]}
                    result["baseline_candidate"] = stronger
            if stronger and best == stronger["state"]:
                v = {"ok": True, "outcome": "baseline"}
            else:
                v = verify(s, best, against=stronger["state"] if stronger else None)
        except SessionError as e:
            v = {"ok": False, "stage": "error", "error": f"{e.kind}: {e.message}"}
        result["verified"] = v
        kept = json.loads(old.read_text())["verified"] if old.exists() else None
        if v.get("ok") and v.get("outcome") == "win":
            result.update(outcome="win", state=best, speedup=v["speedup"], ci95=v["speedup_ci95"])
            if kept and not stronger and kept["speedup_ci95"][0] >= v["speedup_ci95"][0]:
                result["recipe_kept"] = f"the recorded recipe ({kept['speedup']}x, {kept['speedup_ci95']}) is not beaten"
            else:
                result["recipe"] = str(record(s, best, v, report, meta, stronger))
        elif v.get("outcome") == "baseline":
            result.update(outcome="baseline", why=f"the session's source is a stronger amdclang build ({stronger['speedup']:.3f}x over the "
                                                  "baseline) with no machine-level gain on it: a baseline candidate, not a win")
        else:
            result.update(outcome="fallback", why=f"the named state {best} did not verify as a win: "
                                                    f"{v.get('outcome') or v.get('stage')}")
    if result["outcome"] != "win" and old.exists():
        result["recipe_kept"] = "an earlier session's verified recipe stays recorded"
    (s.store.root / "harness-result.json").write_text(json.dumps(result, indent=1, default=str) + "\n")
    log(f"{name}: {result['outcome']}" + (f" {result['speedup']:.3f}x {result['ci95']}" if result["outcome"] == "win" else f" ({result['why']})"))
    return result


def replay(names: list[str] | None = None, root: str | Path | None = None, log=print, update: bool = False) -> dict:
    """Rebuild every recorded recipe from its module text and launch, and verify it again against the
    manifest's baseline. `update`: write the new verdict into the recipe, and drop a recipe that is no
    longer a win (after the baseline became stronger, a recipe that was amdclang's own code is parity)."""
    import tempfile
    root = Path(root or tempfile.mkdtemp(prefix="agc-replay-"))
    out = {}
    for d in sorted(p for p in RECIPES.iterdir() if (p / "recipe.json").exists()) if RECIPES.exists() else []:
        if names and d.name not in names:
            continue
        recipe = json.loads((d / "recipe.json").read_text())
        s = Session.open(RECIPES.parent / f"{d.name}.json", root)
        st = s.adopt((d / "best.s").read_text(), recipe["launch"], recipe["strict"], note="recorded recipe")
        try:
            v = verify(s, st["id"]) if st["id"] != s.base_id and s.store.get(st["id"]).ir != s.store.get(s.base_id).ir else \
                {"ok": True, "outcome": "identical to the baseline"}
        except SessionError as e:
            v = {"ok": False, "stage": "error", "error": f"{e.kind}: {e.message}"}
        out[d.name] = v
        log(f"{d.name:24s} {v.get('outcome') or v.get('stage')} {v.get('speedup')} {v.get('speedup_ci95')}")
        if not update:
            continue
        if v.get("ok") and v.get("outcome") == "win":
            att = {"levels": recipe.get("attribution", {}).get("levels"), "baseline": s.manifest.baseline or "amdclang -O3 on the source as shipped",
                   "over_strongest_amdclang": v["speedup"]}
            c = s.compare(s.ref_id, st["id"], PAIRS)
            if c.get("ok"):
                att["over_shipped_O3"] = c["speedup_b_over_a"]
            recipe.update(attribution=att, recorded=time.strftime("%Y-%m-%d"),
                          verified={**{k: v.get(k) for k in ("outcome", "speedup", "speedup_ci95", "reference_ms", "candidate_ms", "cases",
                                                             "protocol_version")}, "pairs": PAIRS, "runs": v.get("runs")})
            (d / "recipe.json").write_text(json.dumps(recipe, indent=1) + "\n")
        else:
            shutil.rmtree(d)
    return out
