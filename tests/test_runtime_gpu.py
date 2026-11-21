"""M1 on the device: the amdclang build of AXPY passes the battery and is timed; wrong kernels are
rejected; the A/A control is at parity and a slower kernel is measured as slower."""
import json

import pytest

from agc.runtime.timing import PROTOCOL_VERSION

from agc.manifest import Manifest
from agc.runtime import harness, toolchain
from agc.runtime.executor import run_job
from agc.runtime.timing import TimingProtocol
from conftest import KERNELS, gpu

pytestmark = gpu

AXPY = """#include <hip/hip_runtime.h>
extern "C" __global__ void axpy(const float* x, float* y, float a, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    BODY
}
"""
GOOD = "if (i < n) y[i] = a * x[i] + y[i];"


def variant(tmp_path, body, name="v"):
    src = tmp_path / f"{name}.hip"
    src.write_text(AXPY.replace("BODY", body))
    return toolchain.hip_build(src).hsaco


@pytest.fixture(scope="module")
def m():
    return Manifest.load(KERNELS / "axpy.json")


@pytest.fixture(scope="module")
def ref(m):
    return harness.reference_build(m).hsaco


def test_info():
    r = run_job({"kind": "info"})
    assert "MI355X" in r["device"]["name"] and r["devices_visible"] == 1
    assert r["gpu"]["device"] in range(8) and r["clocks"]["levels"]


def test_battery_passes(m, ref, agc_root):
    r = harness.check(m, ref)
    assert r["ok"] and r["cases_run"] == r["cases_total"] > 20, r["failures"]
    assert r["resources"]["vgprs"] == 6 and r["resources"]["lds_bytes"] == 0
    assert (agc_root / "gpu_account.jsonl").exists() and (agc_root / "secret").stat().st_mode & 0o777 == 0o600


@pytest.mark.parametrize("body, symptom", [
    ("if (i < n) y[i] = a * x[i] - y[i];", "mismatch"),
    ("if (i < n - 1) y[i] = a * x[i] + y[i];", "mismatch"),                      # last element not computed
    ("if (i < n) { y[i] = a * x[i] + y[i]; ((float*)x)[i] = 0; }", "input"),     # writes a pure input
    ("if (i <= n) y[i] = a * x[i] + y[i]; if (n == 4194304 && i == 5) y[i] = 0;", "mismatch"),  # keyed to one size
])
def test_wrong_kernels_are_rejected(m, tmp_path, agc_root, body, symptom):
    r = harness.check(m, variant(tmp_path, body))
    assert not r["ok"] and r["failures"]
    f = r["failures"][0]
    if symptom == "input":
        assert f["inputs_modified"] == ["x"]
    else:
        assert f["tensors"][0]["mismatches"] >= 1


def test_abi_mismatch_is_a_legible_error(m, tmp_path, agc_root):
    src = tmp_path / "abi.hip"
    src.write_text('#include <hip/hip_runtime.h>\nextern "C" __global__ void axpy(const float* x, float* y, int n) {}\n')
    r = harness.check(m, toolchain.hip_build(src).hsaco, quick=True)
    assert not r["ok"] and r["error"]["type"] == "abi" and "3 arguments" in r["error"]["message"]


def test_bench_and_aa_control(m, ref, agc_root):
    r = harness.bench(m, ref)
    assert r["ok"] and r["verification"]["ok"] and r["protocol"]["version"] == PROTOCOL_VERSION
    t = r["timing"]
    assert t["n"] >= 30 and 0.05 < t["median_ms"] < 5 and r["case"].endswith("[N=67108864]")
    assert t["median_ms"] <= r["wall_median_ms"] < t["median_ms"] + 0.2      # the event time is bounded by wall-clock
    aa = harness.paired(m, ref, ref)
    assert aa["ok"] and aa["outcome"] == "parity", aa
    assert 0.98 <= aa["speedup"] <= 1.02, aa


def test_paired_separates_a_slower_kernel(m, ref, tmp_path, agc_root):
    slow = variant(tmp_path, "if (i < n) { float t = x[i]; for (int k = 0; k < 64; ++k) t = sinf(t) + x[i]; "
                             "y[i] = a * x[i] + y[i] + 0.0f * t; }")
    proto = TimingProtocol(pairs=30)
    r = harness.paired(m, ref, slow, protocol=proto, symbols={"N": 1 << 22})
    assert r["ok"] and r["outcome"] == "loss" and r["speedup_ci95"][1] < 1.0, r
    r = harness.paired(m, slow, ref, protocol=proto, symbols={"N": 1 << 22})
    assert r["ok"] and r["outcome"] == "win" and r["speedup_ci95"][0] > 1.0, r


def test_paired_refuses_a_wrong_candidate(m, ref, tmp_path, agc_root):
    r = harness.paired(m, ref, variant(tmp_path, "if (i < n) y[i] = a * x[i];"), symbols={"N": 1 << 20})
    assert not r["ok"] and r["failed"] == "candidate" and "speedup" not in r


def test_cli(m, tmp_path, agc_root, capsys):
    from agc.cli import main
    out = tmp_path / "axpy.hsaco"
    assert main(["build", str(m.path), "-o", str(out), "--asm", str(tmp_path / "axpy.s")]) == 0
    built = json.loads(capsys.readouterr().out)
    assert built["kernel"] == "axpy" and built["vgprs"] == 6 and "v_fmac_f32" in (tmp_path / "axpy.s").read_text()
    assert main(["check", str(m.path), "--hsaco", str(out), "--quick"]) == 0
    assert json.loads(capsys.readouterr().out)["ok"]
