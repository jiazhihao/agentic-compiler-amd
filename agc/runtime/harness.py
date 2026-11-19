"""Compiler-owned verification and measurement of a code object against its manifest
(design D7): the caller supplies a code object; the oracle, inputs, tolerances and protocol
come from the manifest and from here. Each call is one executor job.
"""
from __future__ import annotations

import base64
from pathlib import Path

from ..manifest import Manifest, ManifestError
from . import toolchain
from .executor import default_root, run_job
from .inputs import build_battery, hidden_secret, public_view
from .timing import TimingProtocol


def reference_build(m: Manifest) -> toolchain.HipBuild:
    """amdclang's build of the manifest's HIP source: the baseline and, with no reference program, the oracle."""
    if m.source is None:
        raise ManifestError(f"manifest {m.name} has no HIP source")
    return toolchain.hip_build(m.source, [*toolchain.HIP_FLAGS, *m.hip_flags], mcpu=m.arch)


def _b64(image: bytes) -> str:
    return base64.b64encode(image).decode()


def _job(m: Manifest, kind: str, **fields) -> dict:
    job = {"kind": kind, "manifest": m.to_dict(), "manifest_path": str(m.path), **fields}
    if m.reference.kind == "none" and kind in ("check", "bench") and m.source is not None:
        job["oracle_hsaco"] = _b64(reference_build(m).hsaco)
    return job


def check(m: Manifest, hsaco: bytes, *, quick: bool = False, root: Path | None = None, launch: dict | None = None,
          **run) -> dict:
    """The battery: every case must match the reference within the manifest's tolerances."""
    root = root or default_root()
    cases = build_battery(m, hidden_secret(root), quick=quick)
    r = run_job(_job(m, "check", hsaco=_b64(hsaco), cases=[c.to_dict() for c in cases], launch=launch), root=root,
                timeout=run.pop("timeout", 1800.0), **run)
    r["cases"] = public_view(cases[:r.get("cases_run", 0)])
    return r


def bench(m: Manifest, hsaco: bytes, *, protocol: TimingProtocol | None = None, symbols: dict | None = None,
          root: Path | None = None, launch: dict | None = None, **run) -> dict:
    """Time one code object (and verify what was timed)."""
    return run_job(_job(m, "bench", hsaco=_b64(hsaco), protocol=(protocol or TimingProtocol()).to_dict(),
                        symbols=symbols, launch=launch), root=root or default_root(), **run)


def paired(m: Manifest, reference: bytes, candidate: bytes, *, protocol: TimingProtocol | None = None,
           symbols: dict | None = None, root: Path | None = None, reference_launch: dict | None = None,
           candidate_launch: dict | None = None, **run) -> dict:
    """Speedup of `candidate` over `reference`, launched alternately in one process. `outcome` is
    `win` or `loss` only when the 95 % CI of the speedup excludes 1."""
    return run_job(_job(m, "paired", reference_hsaco=_b64(reference), candidate_hsaco=_b64(candidate),
                        protocol=(protocol or TimingProtocol()).to_dict(), symbols=symbols,
                        reference_launch=reference_launch, candidate_launch=candidate_launch),
                   root=root or default_root(), **run)
