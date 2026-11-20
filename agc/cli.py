"""`agc`: build, check and bench a manifest.

  agc build  M.json [-o out.hsaco] [--asm out.s]   amdclang build of the HIP source
  agc check  M.json [--hsaco F] [--quick]          battery against the reference program
  agc bench  M.json [--hsaco F] [--warm]           timing; with --hsaco, paired against amdclang
  agc static M.json [--asm F.s]                    static checks on the amdclang build's assembly (or F.s)
  agc run    M.json [--edit BODY.s] [--quick]      session: import, optional edit, static check, battery, paired bench
  agc run    M.json --generate [T] [--param k=v]   session: compile the manifest's tair program with a template
  agc optimize M.json                              the default policy: best verified candidate, or the amdclang build
  agc agent  M.json [--minutes N] [--model M]      one agent session on the kernel, verified and recorded by the harness
  agc replay [KERNEL ...]                          rebuild and re-measure the recorded session recipes
  agc info                                         device and toolchain facts
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .manifest import Manifest, ManifestError
from .runtime import harness, toolchain
from .runtime.executor import ExecutorError, account_summary, run_job
from .runtime.timing import TimingProtocol


def _emit(obj) -> None:
    json.dump(obj, sys.stdout, indent=1, default=str)
    sys.stdout.write("\n")


def _candidate(args, m) -> bytes:
    return Path(args.hsaco).read_bytes() if args.hsaco else harness.reference_build(m).hsaco


def cmd_build(args) -> int:
    m = Manifest.load(args.manifest)
    b = harness.reference_build(m)
    if args.output:
        Path(args.output).write_bytes(b.hsaco)
    if args.asm:
        Path(args.asm).write_text(b.asm)
    k = next(k for k in toolchain.metadata(b.hsaco)["amdhsa.kernels"] if m.entry in k[".name"])
    _emit({"name": m.name, "kernel": k[".name"], "bytes": len(b.hsaco), "flags": b.flags, "cache_key": b.key,
           "vgprs": k[".vgpr_count"], "agprs": k.get(".agpr_count", 0), "sgprs": k[".sgpr_count"],
           "lds_bytes": k[".group_segment_fixed_size"], "toolchain": toolchain.identity()})
    return 0


def cmd_check(args) -> int:
    m = Manifest.load(args.manifest)
    r = harness.check(m, _candidate(args, m), quick=args.quick, device=args.device)
    r.pop("cases", None)
    _emit(r)
    return 0 if r.get("ok") else 1


def cmd_bench(args) -> int:
    m = Manifest.load(args.manifest)
    proto = TimingProtocol(cache="warm" if args.warm else "flush")
    ref = harness.reference_build(m).hsaco if m.source else None
    if args.hsaco and ref is not None:
        r = harness.paired(m, ref, Path(args.hsaco).read_bytes(), protocol=proto, device=args.device)
    else:
        r = harness.bench(m, _candidate(args, m), protocol=proto, device=args.device)
        if ref is not None and r.get("ok"):          # the A/A control: the same code object against itself
            aa = harness.paired(m, ref, ref, protocol=proto, device=args.device)
            r["aa_control"] = {k: aa.get(k) for k in ("speedup", "speedup_ci95", "outcome")}
    _emit(r)
    return 0 if r.get("ok") else 1


def cmd_static(args) -> int:
    from .mir import check, parse
    m = Manifest.load(args.manifest)
    text = Path(args.asm).read_text() if args.asm else harness.reference_build(m).asm
    r = check.static_check(parse(text))
    _emit({"ok": r["ok"], "findings": r["findings"],
           "kernels": [{"name": k.name, "blocks": len(k.blocks), "instructions": sum(1 for _ in k.insts())}
                       for k in parse(text).kernels]})
    return 0 if r["ok"] else 1


def cmd_run(args) -> int:
    """One pass of the loop on a manifest: the amdclang import, or that with the kernel body replaced."""
    from .session import Session, SessionError
    try:
        s = Session.open(args.manifest, quick=args.quick)
        sid = s.ref_id
        if args.generate is not None:
            params = {k: json.loads(v) for k, v in (kv.split("=", 1) for kv in args.param)}
            sid = s.generate(args.generate or None, params)["id"]
        elif sid is None:
            raise SessionError("parameter", "this manifest has no HIP source: use --generate")
        if args.edit:
            sid = s.edit_ir(sid, Path(args.edit).read_text(), note=f"agc run --edit {args.edit}")["id"]
        out = {"session": s.id, "state": sid, "static": s.static_check(sid)}
        if out["static"]["ok"]:
            out["check"] = s.check(sid)
            if out["check"]["ok"]:
                out["bench"] = s.bench(sid)
        _emit(out)
        return 0 if out.get("bench", {}).get("ok") else 1
    except SessionError as e:
        _emit(e.to_dict())
        return 2


def cmd_optimize(args) -> int:
    from .session import Session, SessionError
    from .session.policy import optimize
    try:
        s = Session.open(args.manifest)
        r = optimize(s, log=lambda row: print(json.dumps({k: row.get(k) for k in ("how", "outcome", "speedup", "ci95", "reason")}), file=sys.stderr))
        if args.output:
            from .mir import emit
            Path(args.output).write_bytes(emit.build(s.module(r["chosen"]["state"]), check=False).hsaco)
        _emit(r)
        return 0
    except SessionError as e:
        _emit(e.to_dict())
        return 2


def cmd_agent(args) -> int:
    from . import agent
    r = agent.run(args.manifest, minutes=args.minutes, benches=args.benches, model=args.model, policy=not args.no_policy, session=not args.verify_only,
                  extra=args.extra or "", log=lambda t: print(t, file=sys.stderr))
    _emit({k: r.get(k) for k in ("kernel", "outcome", "speedup", "ci95", "why", "summary", "friction", "recipe", "agent")})
    return 0


def cmd_replay(args) -> int:
    from . import agent
    r = agent.replay(args.kernels or None, log=lambda t: print(t, file=sys.stderr))
    _emit(r)
    return 0 if all(v.get("outcome") == "win" for v in r.values()) else 1


def cmd_info(args) -> int:
    _emit({**run_job({"kind": "info"}, device=args.device), "toolchain": toolchain.identity()})
    return 0


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="agc", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--device", default=None, help="GPU ordinal (default: AGC_GPU or the first free one)")
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("build"); p.add_argument("manifest"); p.add_argument("-o", "--output"); p.add_argument("--asm")
    p.set_defaults(fn=cmd_build)
    p = sub.add_parser("check"); p.add_argument("manifest"); p.add_argument("--hsaco"); p.add_argument("--quick", action="store_true")
    p.set_defaults(fn=cmd_check)
    p = sub.add_parser("bench"); p.add_argument("manifest"); p.add_argument("--hsaco"); p.add_argument("--warm", action="store_true")
    p.set_defaults(fn=cmd_bench)
    p = sub.add_parser("static"); p.add_argument("manifest"); p.add_argument("--asm"); p.set_defaults(fn=cmd_static)
    p = sub.add_parser("run"); p.add_argument("manifest"); p.add_argument("--edit"); p.add_argument("--quick", action="store_true")
    p.add_argument("--generate", nargs="?", const="", metavar="TEMPLATE", help="compile the tair program (default template if omitted)")
    p.add_argument("--param", action="append", default=[], metavar="K=V", help="template parameter (JSON value)")
    p.set_defaults(fn=cmd_run)
    p = sub.add_parser("optimize"); p.add_argument("manifest"); p.add_argument("-o", "--output", help="write the chosen code object")
    p.set_defaults(fn=cmd_optimize)
    p = sub.add_parser("agent"); p.add_argument("manifest"); p.add_argument("--minutes", type=int, default=45)
    p.add_argument("--benches", type=int, default=30); p.add_argument("--model"); p.add_argument("--no-policy", action="store_true")
    p.add_argument("--verify-only", action="store_true", help="no new session: verify and record the last session's report")
    p.add_argument("--extra", help="text appended to the session prompt"); p.set_defaults(fn=cmd_agent)
    p = sub.add_parser("replay"); p.add_argument("kernels", nargs="*"); p.set_defaults(fn=cmd_replay)
    p = sub.add_parser("info"); p.set_defaults(fn=cmd_info)
    args = ap.parse_args(argv)
    try:
        return args.fn(args)
    except (ManifestError, ExecutorError, toolchain.ToolchainError, ValueError) as e:
        _emit({"ok": False, "error": {"type": type(e).__name__, "message": str(e)}})
        return 2
    finally:
        if account_summary()["gpu_jobs"]:
            print(json.dumps(account_summary()), file=sys.stderr)


if __name__ == "__main__":
    sys.exit(main())
