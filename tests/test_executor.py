import os
import subprocess
import sys
import time

import pytest

from agc.runtime import executor


@pytest.fixture
def locks(tmp_path, monkeypatch):
    monkeypatch.setenv("AGC_GPU_LOCK_DIR", str(tmp_path))
    monkeypatch.setenv("AGC_GPU_COUNT", "2")
    executor.device_count.cache_clear()
    yield tmp_path
    executor.device_count.cache_clear()


def test_auto_takes_a_free_device(locks):
    with executor.gpu_lock("auto") as a:
        with executor.gpu_lock("auto") as b:
            assert {a["device"], b["device"]} == {0, 1}
            with pytest.raises(executor.ExecutorError, match="timed out"):
                with executor.gpu_lock("auto", timeout=0.1):
                    pass
    with executor.gpu_lock(1) as c:
        assert c["device"] == 1


def test_lock_excludes_other_processes(locks):
    code = ("import sys, time; from agc.runtime import executor\n"
            "with executor.gpu_lock(0) as h:\n"
            "    print('held', flush=True); time.sleep(float(sys.argv[1]))\n")
    env = {**os.environ}
    holder = subprocess.Popen([sys.executable, "-c", code, "1.0"], stdout=subprocess.PIPE, text=True, env=env)
    assert holder.stdout.readline().strip() == "held"
    t0 = time.monotonic()
    with executor.gpu_lock(0) as h:
        waited = time.monotonic() - t0
    holder.wait()
    assert waited > 0.5 and h["queue_s"] > 0.5


def test_batch_yields_to_interactive(locks):
    wdir = executor.lock_path(0).with_name(f"agc-gpu-{os.getuid()}.waiters")
    wdir.mkdir()
    (wdir / f"{os.getpid()}-1").write_text("")           # a live interactive waiter
    with pytest.raises(executor.ExecutorError, match="timed out"):
        with executor.gpu_lock(0, priority="batch", timeout=0.2):
            pass
    (wdir / f"{os.getpid()}-1").unlink()
    (wdir / "999999999-1").write_text("")                # a dead waiter's marker is cleaned up
    with executor.gpu_lock(0, priority="batch", timeout=1.0):
        pass
    with pytest.raises(executor.ExecutorError, match="priority"):
        with executor.gpu_lock(0, priority="urgent"):
            pass
