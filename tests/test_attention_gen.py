"""The MFMA attention template (`agc.gen.attention`): the program pattern it accepts, what it generates, and (GPU)
that the generated kernels pass the battery of `bench/llm/fa_attention`."""
import json
from pathlib import Path

import numpy as np
import pytest

from agc import gen
from agc.gen import attention
from agc.manifest import Manifest
from agc.session import Session
from agc.tair.interp import evaluate
from agc.tair.text import parse
from conftest import gpu, needs_toolchain

LLM = Path(__file__).resolve().parent.parent / "bench" / "llm"
PROGRAM = (LLM / "fa_attention.tair").read_text()


def manifest(width: int = 64) -> Manifest:
    d = json.loads((LLM / "fa_attention.json").read_text())
    if width != 64:                          # the HIP source is written for 64: a program-only manifest
        for k in ("source", "baseline"):
            d.pop(k, None)
        for p in d["params"]:
            if p.get("shape") and len(p["shape"]) == 2:
                p["shape"][1] = width
        d["program"] = {"text": PROGRAM.replace("64]", f"{width}]")}
    return Manifest.from_dict(d, LLM / "fa_attention.json")


def test_the_pattern_is_matched_with_and_without_scale_and_lse():
    assert attention.matches(parse(PROGRAM))
    no_lse = PROGRAM.replace(", lse: f32[NQ]", "").replace("  lse = m + log(s)\n", "")
    assert attention.matches(parse(no_lse))
    no_scale = no_lse.replace(", scale: f32", "").replace("S * scale", "S")
    assert attention.matches(parse(no_scale))
    assert not attention.matches(parse(PROGRAM.replace("reduce max", "reduce min")))
    assert not attention.matches(parse(PROGRAM.replace('"qk,kd->qd"(W, V)', '"qk,kd->qd"(P, V)')))
    assert not attention.matches(parse((LLM.parent.parent / "tests" / "kernels" / "softmax.tair").read_text()))


def test_tair_log_and_the_program_semantics():
    rng = np.random.default_rng(0)
    Q, K, V = (rng.standard_normal(s).astype(np.float32) for s in ((5, 64), (9, 64), (9, 64)))
    out = evaluate(parse(PROGRAM), {"Q": Q, "K": K, "V": V, "scale": 0.125}, np.float64)
    s = 0.125 * Q.astype(np.float64) @ K.astype(np.float64).T
    w = np.exp(s - s.max(1, keepdims=True))
    assert np.allclose(out["out"], (w / w.sum(1, keepdims=True)) @ V, rtol=1e-12)
    assert np.allclose(out["lse"], s.max(1) + np.log(w.sum(1)), rtol=1e-12) and out["lse"].shape == (5,)


@needs_toolchain
@pytest.mark.parametrize("params", [{"waves": 1, "ahead": 0}, {"waves": 4, "ahead": 1}, {"waves": 8, "ahead": 1}])
def test_generated_code_is_statically_clean(params, tmp_path):
    m = manifest()
    assert gen.applicable(m) == ["attention_mfma"]
    s = Session.from_manifest(m, tmp_path)
    st = s.generate("attention_mfma", params)
    assert s.static_check(st["id"])["ok"]
    ir = s.store.get(st["id"]).ir
    assert ir.count("v_mfma_f32_16x16x4_f32") == 32 * (2 if params["ahead"] else 1)
    assert s.launch_of(st["id"]) == {"grid": ["cdiv(NQ, 16)"], "block": [64 * params["waves"]], "lds": 0}
    assert ("s_barrier" in ir) == (params["waves"] > 1)


@needs_toolchain
def test_two_tiles_of_loads_in_flight_at_width_128_stay_within_the_wait_counter(tmp_path):
    """80 vector loads are outstanding; `s_waitcnt vmcnt` cannot name more than 63 (fix_waits used to emit 79)."""
    s = Session.from_manifest(manifest(128), tmp_path)
    st = s.generate("attention_mfma", {"waves": 4, "ahead": 1})
    assert s.static_check(st["id"])["ok"]


def test_refusals():
    m = manifest()
    with pytest.raises(gen.GenError, match="waves"):
        attention.generate(m, gen.program_of(m), waves=3)
    d = json.loads((LLM / "fa_attention.json").read_text())
    for k in ("source", "baseline"):
        d.pop(k, None)
    for p in d["params"]:
        if p.get("shape") and len(p["shape"]) == 2:
            p["shape"][1] = 48
    d["program"] = {"text": PROGRAM.replace("64]", "48]")}
    m48 = Manifest.from_dict(d, LLM / "fa_attention.json")
    with pytest.raises(gen.GenError, match="row width"):
        attention.generate(m48, gen.program_of(m48))


@pytest.mark.parametrize("width,params", [pytest.param(64, {"waves": 1, "ahead": 0}, marks=gpu),
                                          pytest.param(64, {"waves": 4, "ahead": 1}, marks=gpu),
                                          pytest.param(128, {"waves": 4, "ahead": 1}, marks=gpu)])
def test_generated_attention_passes_the_battery(width, params, tmp_path):
    s = Session.from_manifest(manifest(width), tmp_path)
    st = s.generate("attention_mfma", params)
    assert s.check(st["id"])["ok"]
