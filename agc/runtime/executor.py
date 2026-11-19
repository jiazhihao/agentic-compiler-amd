"""Runs worker jobs in a subprocess under a per-device GPU lock, with a timeout.
Everything that touches a GPU goes through `run_job` (design D8).

The lock is machine-wide per device (`/tmp/agc-gpu-<uid>-<device>.lock`), so one measurement
runs on a device at a time across all sessions and test processes. A job names its device
(`device=N`, or the `AGC_GPU` environment variable) or takes the first free one ("auto").
A `batch` job does not compete for a device while an `interactive` job is waiting for it.
"""
from __future__ import annotations

import fcntl
import functools
import json
import os
import subprocess
import sys
import time
from contextlib import contextmanager
from pathlib import Path

RESULT_MARK = "AGC_RESULT "
PRIORITIES = ("interactive", "batch")
# this process's share of the GPU queue
ACCOUNT = {"jobs": 0, "queue_s": 0.0, "run_s": 0.0}


class ExecutorError(RuntimeError):
    pass


def default_root() -> Path:
    """Where sessions keep the hidden-seed secret and the GPU account."""
    return Path(os.environ.get("AGC_ROOT", Path.home() / ".cache" / "agc"))


def lock_path(device: int) -> Path:
    base = os.environ.get("AGC_GPU_LOCK_DIR", "/tmp")       # /tmp, not TMPDIR: one queue per machine
    return Path(base) / f"agc-gpu-{os.getuid()}-{device}.lock"


@functools.cache
def device_count() -> int:
    """Number of GPUs, counted without initializing HIP in this process."""
    env = os.environ.get("AGC_GPU_COUNT")
    if env:
        return int(env)
    n = 0
    for d in Path("/sys/class/drm").glob("card*/device/vendor"):
        try:
            if d.read_text().strip() == "0x1002" and (d.parent / "pp_dpm_sclk").exists():
                n += 1
        except OSError:
            pass
    return n


def clock_state(device: int | None = None) -> dict:
    """Core clock levels as sysfs reports them (the active one is starred). On an SR-IOV virtual
    function the clock cannot be set; this is recorded with every timing."""
    out = {"controllable": False, "levels": None}
    cards = sorted((p for p in Path("/sys/class/drm").glob("card*/device/pp_dpm_sclk")),
                   key=lambda p: int(p.parts[-3][4:]))
    if cards and device is not None and device < len(cards):
        try:
            out["levels"] = cards[device].read_text().split("\n")[:-1]
        except OSError:
            pass
    return out


def _interactive_waiting(wdir: Path) -> bool:
    if not wdir.exists():
        return False
    for f in list(wdir.iterdir()):
        try:
            os.kill(int(f.name.split("-")[0]), 0)
            return True
        except PermissionError:
            return True
        except (ValueError, ProcessLookupError):
            try:
                f.unlink()
            except OSError:
                pass
    return False


@contextmanager
def gpu_lock(device: int | str = "auto", priority: str = "interactive", timeout: float | None = None):
    """Hold one device's lock; yields {"device", "queue_s"}. `device="auto"` takes the first free one."""
    if priority not in PRIORITIES:
        raise ExecutorError(f"unknown GPU priority {priority!r} (one of {PRIORITIES})")
    n = device_count()
    if device == "auto":
        if n == 0:
            raise ExecutorError("no AMD GPU found")
        start = os.getpid() % n                           # spread concurrent processes over the devices
        candidates = [(start + i) % n for i in range(n)]
    else:
        candidates = [int(device)]
    fds = {}
    for d in candidates:
        p = lock_path(d)
        fds[d] = os.open(p, os.O_RDWR | os.O_CREAT, 0o666)
    wdir = lock_path(candidates[0]).with_name(f"agc-gpu-{os.getuid()}.waiters")
    marker = None
    t0 = time.monotonic()
    got = None
    try:
        if priority == "interactive":
            wdir.mkdir(parents=True, exist_ok=True)
            marker = wdir / f"{os.getpid()}-{time.monotonic_ns()}"
            marker.write_text("")
        delay = 0.005
        while got is None:
            if priority == "interactive" or not _interactive_waiting(wdir):
                for d in candidates:
                    try:
                        fcntl.flock(fds[d], fcntl.LOCK_EX | fcntl.LOCK_NB)
                        got = d
                        break
                    except BlockingIOError:
                        pass
            if got is None:
                if timeout is not None and time.monotonic() - t0 >= timeout:
                    raise ExecutorError(f"GPU queue timed out after {timeout}s")
                time.sleep(delay)
                delay = min(delay * 1.5, 0.2)
    except BaseException:
        for fd in fds.values():
            os.close(fd)
        raise
    finally:
        if marker is not None:
            try:
                marker.unlink()
            except OSError:
                pass
    for d, fd in fds.items():
        if d != got:
            os.close(fd)
    try:
        yield {"device": got, "queue_s": time.monotonic() - t0}
    finally:
        fcntl.flock(fds[got], fcntl.LOCK_UN)
        os.close(fds[got])


def run_job(job: dict, *, device: int | str | None = None, timeout: float = 600.0,
            priority: str | None = None, root: Path | None = None) -> dict:
    """Run one worker job on one GPU. Returns the worker's result dict with `gpu` (device, queue
    and run seconds) and `clocks` added. A kernel failure is a result with `error`; a crash,
    hang or protocol failure of the worker raises ExecutorError."""
    priority = priority or os.environ.get("AGC_GPU_PRIORITY", "interactive")
    if device is None:
        device = os.environ.get("AGC_GPU", "auto")
    kind = str(job.get("kind", "job"))
    with gpu_lock(device, priority) as held:
        dev = held["device"]
        env = {**os.environ, "HIP_VISIBLE_DEVICES": str(dev), "PYTHONUNBUFFERED": "1"}
        env.pop("ROCR_VISIBLE_DEVICES", None)
        t0 = time.monotonic()
        try:
            proc = subprocess.run([sys.executable, "-m", "agc.runtime.worker"], input=json.dumps(job),
                                  capture_output=True, text=True, timeout=timeout, env=env)
        except subprocess.TimeoutExpired as e:
            err = e.stderr.decode(errors="replace") if isinstance(e.stderr, bytes) else (e.stderr or "")
            raise ExecutorError(f"worker timed out after {timeout}s (kernel hang?)\nstderr: {err[-2000:]}") from None
        finally:
            run_s = time.monotonic() - t0
            use = {"device": dev, "priority": priority, "queue_s": round(held["queue_s"], 4), "run_s": round(run_s, 4)}
            _record(root, kind, use)
        clocks = clock_state(dev)
    line = next((l for l in reversed(proc.stdout.splitlines()) if l.startswith(RESULT_MARK)), None)
    if line is None:
        raise ExecutorError(f"worker crashed (exit {proc.returncode}) without a result; stderr:\n{proc.stderr[-4000:]}")
    try:
        result = json.loads(line[len(RESULT_MARK):])
    except json.JSONDecodeError:
        raise ExecutorError(f"worker result is not JSON: {line[:500]}") from None
    if not isinstance(result, dict):
        raise ExecutorError("worker produced an invalid result object")
    result["gpu"], result["clocks"] = use, clocks
    return result


def _record(root, kind, use):
    ACCOUNT["jobs"] += 1
    ACCOUNT["queue_s"] += use["queue_s"]
    ACCOUNT["run_s"] += use["run_s"]
    if root is not None:
        try:
            Path(root).mkdir(parents=True, exist_ok=True)
            with open(Path(root) / "gpu_account.jsonl", "a") as f:
                f.write(json.dumps({"t": time.time(), "pid": os.getpid(), "kind": kind, **use}) + "\n")
        except OSError:
            pass


def account_summary() -> dict:
    return {"gpu_jobs": ACCOUNT["jobs"], "gpu_s": round(ACCOUNT["run_s"], 1), "queue_s": round(ACCOUNT["queue_s"], 1)}
