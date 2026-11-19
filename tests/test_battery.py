import numpy as np
import pytest

from agc.dtypes import DTYPES, dtype
from agc.manifest import Manifest
from agc.runtime import reference
from agc.runtime.compare import compare_tensor
from agc.runtime.inputs import (DISTRIBUTIONS, Case, build_battery, generate, generate_inputs, poison,
                                public_view, shape_variants)
from agc.runtime.timing import TimingProtocol, converged, paired_orders, paired_summary, summarize
from conftest import KERNELS


@pytest.fixture
def m():
    return Manifest.load(KERNELS / "axpy.json")


def test_battery_shape(m):
    variants = shape_variants(m)
    assert variants[0] == m.shapes and {"N": 1} in variants and {"N": m.shapes["N"] + 1} in variants
    cases = build_battery(m, b"s" * 32)
    assert sum(c.hidden for c in cases) >= 3
    assert {c.distribution for c in cases} == set(DISTRIBUTIONS)
    assert all(v["seed"] is None for v in public_view(cases) if v["hidden"])
    other = build_battery(m, b"t" * 32)
    assert [c.seed for c in cases if c.hidden] != [c.seed for c in other if c.hidden]
    assert len(build_battery(m, b"s" * 32, quick=True)) == len(variants)


@pytest.mark.parametrize("name", [n for n in DTYPES])
def test_generate_every_dtype(m, name):
    p = m.param("x")
    p.dtype = dtype(name)
    for dist in DISTRIBUTIONS:
        a = generate(p, (64, 3), Case(dist, 1, {}))
        assert a.shape == (64, 3) and a.dtype == p.dtype.storage
        assert np.array_equal(a, generate(p, (64, 3), Case(dist, 1, {})), equal_nan=True)   # deterministic
        if p.dtype.is_float:
            assert np.isfinite(p.dtype.from_storage(a)).all()


def test_reference_and_scale(m):
    r = m.resolve({"N": 1000})
    inputs = generate_inputs(m, r, Case("normal", 0, r.symbols))
    out = reference.evaluate(m, inputs, r)
    assert out["y"].dtype == np.float32 and np.allclose(out["y"], 1.5 * inputs["x"] + inputs["y"])
    s = reference.scale(m, inputs, r)
    assert np.allclose(s["y"], 1.5 * np.abs(inputs["x"]) + np.abs(inputs["y"]))


def test_compare():
    f32 = dtype("f32")
    ref = np.linspace(-4, 4, 100, dtype=np.float32)
    assert compare_tensor("y", ref.copy(), ref, f32, 1e-4, 1e-5).ok
    bad = ref.copy()
    bad[7] += 1.0
    rep = compare_tensor("y", bad, ref, f32, 1e-4, 1e-5)
    assert not rep.ok and rep.mismatches == 1 and rep.first["index"] == [7] and rep.unwritten == 0
    # the cond allowance scales with the magnitude of the terms, not of the (cancelled) result
    assert compare_tensor("y", bad, ref, f32, 0, 0, cond=1e-3, scale=np.full(100, 2000.0)).ok
    # unwritten elements are named as such
    un = ref.copy()
    un[10:20] = poison((10,), f32).view(np.float32)
    rep = compare_tensor("y", un, ref, f32, 1e-4, 1e-5)
    assert not rep.ok and rep.unwritten == 10
    # NaN matches NaN, infinities must agree in sign, a shape mismatch fails
    special = np.array([np.nan, np.inf, -np.inf], np.float32)
    assert compare_tensor("y", special.copy(), special, f32, 0, 0).ok
    assert not compare_tensor("y", np.array([np.nan, -np.inf, -np.inf], np.float32), special, f32, 1, 1).ok
    assert not compare_tensor("y", np.array([0, np.inf, -np.inf], np.float32), special, f32, 1, 1).ok
    assert not compare_tensor("y", ref[:50], ref, f32, 1, 1).ok
    # integers are exact; bf16 compares decoded values
    i32 = dtype("i32")
    a = np.arange(10, dtype=np.int32)
    assert compare_tensor("y", a.copy(), a, i32, 0, 0).ok and not compare_tensor("y", a + 1, a, i32, 0, 0).ok
    bf = dtype("bf16")
    x = bf.to_storage(np.linspace(-2, 2, 50))
    assert compare_tensor("y", x.copy(), x, bf, 0, 0).ok


def test_timing_statistics():
    rng = np.random.default_rng(0)
    proto = TimingProtocol()
    tight = list(1.0 + 0.01 * rng.standard_normal(40))
    assert converged(tight, proto) and not converged(tight[:10], proto)
    assert not converged(list(1.0 + 0.5 * rng.random(40)), proto)
    s = summarize(tight)
    assert s["ci95_median_ms"][0] <= s["median_ms"] <= s["ci95_median_ms"][1]
    order = paired_orders(60, 3)
    assert sum(order) == 30 and order != paired_orders(60, 4)
    ref = 1.0 + 0.02 * rng.standard_normal(60)
    assert paired_summary(ref, ref * (1 + 0.01 * rng.standard_normal(60)))["outcome"] == "parity"
    win = paired_summary(ref, ref / 1.2)
    assert win["outcome"] == "win" and abs(win["speedup"] - 1.2) < 1e-6
    assert paired_summary(ref, ref * 1.2)["outcome"] == "loss"
    with pytest.raises(ValueError):
        TimingProtocol.from_dict({"cache": "cold"})
    with pytest.raises(ValueError):
        TimingProtocol.from_dict({"nonsense": 1})
