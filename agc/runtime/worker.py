"""The GPU worker: one job per process (JSON on stdin, the result on the last stdout line).
Started only by `agc.runtime.executor.run_job`, which holds the device lock and has made the
device ordinal 0 of this process.

Jobs:
  info    device facts
  check   run a code object on battery cases and compare with the reference
  bench   time a code object under the timing protocol (and verify the timed outputs)
  paired  time two code objects alternately; speedup of `candidate` over `reference`
  run     run one case and return the raw outputs (hardware probes)
"""
from __future__ import annotations

import base64
import json
import re
import struct
import sys
import time
import traceback
from pathlib import Path

import numpy as np

from ..arch.model import load as load_arch
from ..manifest import Manifest, eval_expr
from . import hip, reference, toolchain
from .compare import compare_outputs
from .executor import RESULT_MARK
from .inputs import Case, generate_inputs, poison
from .timing import TimingProtocol, converged, paired_orders, paired_summary, summarize


class JobError(Exception):
    def __init__(self, kind: str, message: str, **extra):
        super().__init__(message)
        self.payload = {"type": kind, "message": message, **extra}


def find_kernel(meta: dict, entry: str) -> dict:
    """The metadata of kernel `entry`: an exact symbol, or the one C++-mangled name of it."""
    kernels = meta.get("amdhsa.kernels", [])
    exact = [k for k in kernels if k[".name"] == entry]
    if exact:
        return exact[0]
    mangled = [k for k in kernels if re.match(rf"_Z\w*?{len(entry)}{re.escape(entry)}", k[".name"])]
    if len(mangled) == 1:
        return mangled[0]
    raise JobError("abi", f"kernel {entry!r} not found in the code object "
                   f"(kernels: {[k['.name'] for k in kernels]})")


def pack_args(kmeta: dict, m: Manifest, resolved, pointers: dict[str, int]) -> bytes:
    """The explicit kernel arguments at the offsets the code object's metadata declares."""
    explicit = [a for a in kmeta.get(".args", []) if not a[".value_kind"].startswith("hidden_")]
    if len(explicit) != len(m.params):
        raise JobError("abi", f"the kernel takes {len(explicit)} arguments, the manifest declares {len(m.params)}")
    buf = bytearray(max((a[".offset"] + a[".size"] for a in explicit), default=0))
    for a, p in zip(explicit, m.params):
        if p.kind == "tensor":
            if a[".value_kind"] != "global_buffer" or a[".size"] != 8:
                raise JobError("abi", f"argument {p.name}: the kernel does not take a pointer here ({a['.value_kind']})")
            data = struct.pack("<Q", pointers[p.name])
        else:
            if a[".value_kind"] != "by_value" or a[".size"] != p.dtype.itemsize:
                raise JobError("abi", f"argument {p.name}: the kernel takes {a['.size']} bytes by "
                               f"{a['.value_kind']}, the manifest declares {p.dtype}")
            data = np.asarray(resolved.scalars[p.name]).astype(p.dtype.storage).tobytes()
        buf[a[".offset"]:a[".offset"] + a[".size"]] = data
    return bytes(buf)


class Loaded:
    """A code object's kernel on the device."""

    def __init__(self, dev: hip.Device, image: bytes, entry: str, launch: dict | None = None):
        self.dev = dev
        self.launch = launch          # a generated kernel's own geometry: {"grid": [...], "block": [...], "lds": n}
        self.kmeta = find_kernel(toolchain.metadata(image), entry)
        self.module = dev.load(image)
        self.kernel = self.module.kernel(self.kmeta[".name"])

    def resources(self) -> dict:
        k = self.kmeta
        return {"vgprs": k[".vgpr_count"], "agprs": k.get(".agpr_count", 0), "sgprs": k[".sgpr_count"],
                "lds_bytes": k[".group_segment_fixed_size"], "scratch_bytes": k[".private_segment_fixed_size"],
                "vgpr_spills": k.get(".vgpr_spill_count", 0), "sgpr_spills": k.get(".sgpr_spill_count", 0)}


class Bound:
    """A case's tensors on the device, shared by every kernel run on that case: live buffers the
    kernels read and write, and pristine copies from which `reset` restores them."""

    def __init__(self, dev: hip.Device, m: Manifest, resolved, inputs: dict[str, np.ndarray]):
        self.dev, self.m, self.resolved, self.inputs = dev, m, resolved, inputs
        self.live: dict[str, hip.Buffer] = {}
        self.pristine: dict[str, hip.Buffer] = {}
        for p in m.tensors():
            host = inputs[p.name] if p.role in ("in", "inout") else poison(resolved.tensors[p.name], p.dtype)
            self.live[p.name] = dev.upload(host)
            if p.role != "in":
                self.pristine[p.name] = dev.upload(host)
        self.pointers = {k: b.ptr for k, b in self.live.items()}
        self._prepared: dict = {}

    def reset(self):
        for name, src in self.pristine.items():
            self.dev.copy(self.live[name], src)

    def prepared(self, k: Loaded):
        """The launch of `k` on these buffers as a ready-to-submit callable (built once per kernel)."""
        if id(k) not in self._prepared:
            grid, block, lds = self.resolved.grid, self.resolved.block, self.resolved.lds
            if k.launch:
                sym = self.resolved.symbols
                dims = lambda v: tuple(eval_expr(e, sym) for e in v) + (1,) * (3 - len(v))
                grid, block, lds = dims(k.launch["grid"]), dims(k.launch["block"]), eval_expr(k.launch.get("lds", 0), sym)
                if min(grid) <= 0 or min(block) <= 0:
                    raise JobError("launch", f"launch dims must be positive: grid={grid} block={block}")
            self._prepared[id(k)] = k.kernel.prepare(grid, block, pack_args(k.kmeta, self.m, self.resolved, self.pointers),
                                                     stream=self.dev.stream, lds_bytes=lds)
        return self._prepared[id(k)]

    def launch(self, k: Loaded):
        self.prepared(k)()

    def outputs(self) -> dict[str, np.ndarray]:
        return {p.name: self.dev.download(self.live[p.name], p.dtype.storage, self.resolved.tensors[p.name])
                for p in self.m.outputs()}

    def modified_inputs(self) -> list[str]:
        """Pure inputs the kernel wrote to."""
        return [p.name for p in self.m.tensors() if p.role == "in" and not np.array_equal(
            self.dev.download(self.live[p.name], p.dtype.storage, self.resolved.tensors[p.name]).view(p.dtype.bits_view()),
            self.inputs[p.name].view(p.dtype.bits_view()))]

    def free(self):
        for b in (*self.live.values(), *self.pristine.values()):
            b.free()


def _manifest(job) -> Manifest:
    return Manifest.from_dict(job["manifest"], Path(job["manifest_path"]))


def _image(job, key="hsaco") -> bytes:
    return base64.b64decode(job[key])


def _expected(m, resolved, inputs, bound: Bound, oracle: Loaded | None):
    """Expected outputs and the tolerance scale: the reference program, or the oracle kernel."""
    if m.reference.kind != "none":
        return reference.evaluate(m, inputs, resolved), reference.scale(m, inputs, resolved)
    if oracle is None:
        raise JobError("manifest", "the manifest has no reference program and the job has no oracle code object")
    bound.reset()
    bound.launch(oracle)
    bound.dev.synchronize()
    return bound.outputs(), None


def job_info(job) -> dict:
    return {"device": hip.Device(0).info(), "devices_visible": hip.Device.count()}


def job_check(job) -> dict:
    m = _manifest(job)
    dev = hip.Device(0)
    cand = Loaded(dev, _image(job), m.entry, job.get("launch"))
    oracle = Loaded(dev, _image(job, "oracle_hsaco"), m.entry) if job.get("oracle_hsaco") else None
    reports, ok = [], True
    for cd in job["cases"]:
        case = Case.from_dict(cd)
        resolved = m.resolve(case.symbols)
        inputs = generate_inputs(m, resolved, case)
        bound = Bound(dev, m, resolved, inputs)
        try:
            expected, scale = _expected(m, resolved, inputs, bound, oracle)
            bound.reset()
            bound.launch(cand)
            dev.synchronize()
            rep = compare_outputs(m, case.label, bound.outputs(), expected, scale).to_dict()
            touched = bound.modified_inputs()
            if touched:
                rep["ok"], rep["inputs_modified"] = False, touched
        finally:
            bound.free()
        if case.hidden:                 # a hidden case reports pass / fail only
            rep = {"case": rep["case"], "ok": rep["ok"]}
        ok &= rep["ok"]
        reports.append(rep)
        if not rep["ok"] and job.get("stop_on_failure", True):
            break
    return {"ok": ok, "cases_run": len(reports), "cases_total": len(job["cases"]),
            "failures": [r for r in reports if not r["ok"]], "resources": cand.resources()}


def job_run(job) -> dict:
    """Run one case and return the raw outputs (for probes that discover what the hardware does:
    operand layouts, instruction semantics). Outputs are limited to 4 MiB."""
    m = _manifest(job)
    dev = hip.Device(0)
    k = Loaded(dev, _image(job), m.entry, job.get("launch"))
    case = Case.from_dict(job["case"])
    resolved = m.resolve(case.symbols)
    inputs = generate_inputs(m, resolved, case)
    bound = Bound(dev, m, resolved, inputs)
    try:
        bound.launch(k)
        dev.synchronize()
        outs = bound.outputs()
    finally:
        bound.free()
    if sum(a.nbytes for a in outs.values()) > 4 << 20:
        raise JobError("job", "outputs larger than 4 MiB")
    enc = lambda a: {"dtype": a.dtype.str if a.dtype.kind != "V" else str(a.dtype), "shape": list(a.shape),
                     "data": base64.b64encode(a.tobytes()).decode()}
    return {"ok": True, "outputs": {n: enc(a.view(m.param(n).dtype.bits_view())) for n, a in outs.items()},
            "inputs": {n: enc(a.view(m.param(n).dtype.bits_view())) for n, a in inputs.items()}}


def job_external(job) -> dict:
    """Run a baseline program (a vendor-library benchmark) on this job's device, under the same lock
    as every other measurement. The program prints one JSON object."""
    import subprocess
    try:
        p = subprocess.run([str(a) for a in job["argv"]], capture_output=True, text=True, timeout=job.get("timeout", 300))
    except (OSError, subprocess.TimeoutExpired) as e:
        raise JobError("external", f"cannot run {job['argv'][0]}: {e}") from None
    line = next((l for l in reversed(p.stdout.splitlines()) if l.startswith("{")), None)
    if line is None:
        raise JobError("external", f"no result from {job['argv'][0]} (exit {p.returncode}): {(p.stderr or p.stdout)[-500:]}")
    return json.loads(line)


class _Timer:
    def __init__(self, dev: hip.Device, arch, cache: str):
        self.dev, self.cache = dev, cache
        self.start, self.stop = hip.Event(), hip.Event()
        self.flush_bytes = 2 * (arch.res("l2_per_xcd") * arch.res("xcds") + arch.res("mall"))
        self.flush = dev.alloc(self.flush_bytes) if cache == "flush" else None
        self._tick = 0
        self.wall_ms: list[float] = []      # host wall-clock around the same launch: a sanity bound on the event time

    def time(self, bound: Bound, k: Loaded) -> float:
        submit = bound.prepared(k)                # arguments packed and converted before anything is timed
        bound.reset()
        if self.flush is not None:
            self._tick += 1
            self.dev.memset(self.flush, self._tick & 0xFF)
        self.dev.synchronize()
        t0 = time.perf_counter()
        self.start.record(self.dev.stream)
        submit()
        self.stop.record(self.dev.stream)
        self.stop.synchronize()
        self.wall_ms.append((time.perf_counter() - t0) * 1e3)
        return self.start.elapsed_ms(self.stop)


def _bench_setup(job):
    m = _manifest(job)
    proto = TimingProtocol.from_dict(job.get("protocol"))
    dev = hip.Device(0)
    case = Case(proto.case_distribution, proto.case_seed, dict(job.get("symbols") or m.timing_symbols()))
    resolved = m.resolve(case.symbols)
    inputs = generate_inputs(m, resolved, case)
    bound = Bound(dev, m, resolved, inputs)
    return m, proto, dev, case, resolved, inputs, bound, _Timer(dev, load_arch(m.arch), proto.cache)


def _verify(m, case, bound, expected, scale) -> dict:
    rep = compare_outputs(m, case.label, bound.outputs(), expected, scale).to_dict()
    touched = bound.modified_inputs()
    if touched:
        rep["ok"], rep["inputs_modified"] = False, touched
    return rep


def job_bench(job) -> dict:
    m, proto, dev, case, resolved, inputs, bound, timer = _bench_setup(job)
    k = Loaded(dev, _image(job), m.entry, job.get("launch"))
    oracle = Loaded(dev, _image(job, "oracle_hsaco"), m.entry) if job.get("oracle_hsaco") else None
    expected, scale = _expected(m, resolved, inputs, bound, oracle)
    for _ in range(proto.warmup):
        timer.time(bound, k)
    samples: list[float] = []
    while len(samples) < proto.max_iters and not converged(samples, proto):
        samples.append(timer.time(bound, k))
    rep = _verify(m, case, bound, expected, scale)
    return {"ok": rep["ok"], "protocol": proto.to_dict(), "case": case.label, "timing": summarize(samples),
            "converged": converged(samples, proto), "verification": rep, "resources": k.resources(),
            "flush_bytes": timer.flush_bytes if proto.cache == "flush" else 0,
            "wall_median_ms": float(np.median(timer.wall_ms[proto.warmup:]))}


def job_paired(job) -> dict:
    m, proto, dev, case, resolved, inputs, bound, timer = _bench_setup(job)
    ks = {"reference": Loaded(dev, _image(job, "reference_hsaco"), m.entry, job.get("reference_launch")),
          "candidate": Loaded(dev, _image(job, "candidate_hsaco"), m.entry, job.get("candidate_launch"))}
    expected, scale = _expected(m, resolved, inputs, bound, ks["reference"])
    out = {"protocol": proto.to_dict(), "case": case.label, "resources": {w: k.resources() for w, k in ks.items()}}
    for i in range(proto.warmup):
        for which in ks:
            timer.time(bound, ks[which])
            if i == 0:                  # both code objects are verified before anything is timed
                rep = _verify(m, case, bound, expected, scale)
                if not rep["ok"]:
                    return {**out, "ok": False, "failed": which, "verification": rep}
    samples = {"reference": [], "candidate": []}
    for cand_first in paired_orders(proto.pairs, proto.case_seed):
        for which in (("candidate", "reference") if cand_first else ("reference", "candidate")):
            samples[which].append(timer.time(bound, ks[which]))
    for which in ks:                    # the timed state is verified again after the measurement
        timer.time(bound, ks[which])
        rep = _verify(m, case, bound, expected, scale)
        if not rep["ok"]:
            return {**out, "ok": False, "failed": which, "verification": rep}
    return {**out, "ok": True, **paired_summary(samples["reference"], samples["candidate"], proto.noise_floor)}


JOBS = {"info": job_info, "check": job_check, "bench": job_bench, "paired": job_paired, "run": job_run, "external": job_external}


def main() -> int:
    job = json.loads(sys.stdin.read())
    try:
        fn = JOBS.get(job.get("kind"))
        if fn is None:
            raise JobError("job", f"unknown job kind {job.get('kind')!r}")
        result = fn(job)
    except JobError as e:
        result = {"ok": False, "error": e.payload}
    except hip.HipError as e:
        result = {"ok": False, "error": {"type": "hip", "call": e.call, "code": e.code, "message": e.message}}
    except Exception as e:   # reported to the caller as a structured failure, with the trace
        result = {"ok": False, "error": {"type": type(e).__name__, "message": str(e), "trace": traceback.format_exc()[-3000:]}}
    sys.stdout.write("\n" + RESULT_MARK + json.dumps(result, default=float) + "\n")
    sys.stdout.flush()
    return 0


if __name__ == "__main__":
    sys.exit(main())
