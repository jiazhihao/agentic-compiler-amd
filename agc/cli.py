"""`agc`: build, check and bench a manifest.

  agc build  M.json [-o out.hsaco] [--asm out.s]   amdclang build of the HIP source
  agc check  M.json [--hsaco F] [--quick]          battery against the reference program
  agc bench  M.json [--hsaco F] [--warm]           timing; with --hsaco, paired against amdclang
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
    p = sub.add_parser("info"); p.set_defaults(fn=cmd_info)
    args = ap.parse_args(argv)
    try:
        return args.fn(args)
    except (ManifestError, ExecutorError, toolchain.ToolchainError) as e:
        _emit({"ok": False, "error": {"type": type(e).__name__, "message": str(e)}})
        return 2
    finally:
        if account_summary()["gpu_jobs"]:
            print(json.dumps(account_summary()), file=sys.stderr)


if __name__ == "__main__":
    sys.exit(main())
