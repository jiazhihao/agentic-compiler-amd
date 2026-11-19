"""M2: every corpus kernel builds with amdclang, passes the battery and has a recorded baseline."""
import json

import pytest

from agc import corpus
from agc.runtime import harness, toolchain
from conftest import gpu

NAMES = corpus.names()


def test_corpus_covers_the_code_shapes():
    tags = {t for n in NAMES for t in corpus.load(n).tags}
    assert len(NAMES) >= 12 and {"elementwise", "rowwise", "reduction", "layout", "contraction", "gemm"} <= tags


@pytest.mark.parametrize("name", NAMES)
def test_manifest_and_baseline(name):
    m = corpus.load(name)
    assert m.name == name == m.entry and m.source.name == f"{name}.hip" and m.reference.kind != "none"
    assert m.bench_shapes and m.dynamic
    base = json.loads(corpus.BASELINES.read_text())
    k = base["kernels"][name]
    assert base["protocol"] == "agc-timing-amd-1" and k["symbols"] == m.timing_symbols()
    assert k["median_ms"] > 0.1 and k["converged"]            # well above launch overhead
    assert 0.98 <= k["aa_speedup"] <= 1.02                    # the A/A control of the recording run
    assert 1 <= k["waves_per_simd"] <= 8 and k["resources"]["vgprs"] > 0


@pytest.mark.parametrize("name", [pytest.param(n, marks=gpu) for n in NAMES])
def test_battery(name, agc_root):
    m = corpus.load(name)
    r = harness.check(m, harness.reference_build(m).hsaco)
    assert r["ok"] and r["cases_run"] == r["cases_total"], r.get("failures") or r.get("error")
    base = json.loads(corpus.BASELINES.read_text())
    if base["toolchain"] == toolchain.identity():          # same compiler: same registers as recorded
        assert r["resources"] == base["kernels"][name]["resources"]


@pytest.mark.parametrize("contract, kernel", [pytest.param("rmsnorm", "layernorm", marks=gpu)])
def test_a_kernel_fails_another_kernels_contract(contract, kernel, agc_root):
    """A code object that computes something else is rejected, whether by its ABI or by its results."""
    wrong = toolchain.hip_build(corpus.CORPUS_DIR / f"{kernel}.hip").hsaco
    assert not harness.check(corpus.load(contract), wrong, quick=True)["ok"]
