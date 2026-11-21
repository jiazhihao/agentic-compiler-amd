"""Fusing tair programs (`agc.tair.fuse`): composition, renaming, shapes, and the fused manifest."""
import numpy as np
import pytest

from agc import corpus, gen
from agc.manifest import Manifest
from agc.tair.fuse import fuse, fuse_manifests
from agc.tair.interp import evaluate
from agc.tair.ir import TairError
from agc.tair.text import parse

RMS = parse("tair rmsnorm(x: f32[R, C], w: f32[C], eps: f32) -> (y: f32[R, C]) {\n ms = reduce mean(x * x)\n y = x * rsqrt(ms + eps) * w\n}")
GELU = parse("tair gelu(x: f32[N]) -> (y: f32[N]) {\n y = 0.5 * x * (1.0 + tanh(0.7978845608 * (x + 0.044715 * x * x * x)))\n}")


def test_the_fused_program_computes_the_composition():
    f = fuse(RMS, GELU, {"x": "y"})
    assert [p.name for p in f.params] == ["x", "w", "eps"] and [(o.name, o.shape) for o in f.outputs] == [("gelu_y", ("R", "C"))]
    rng = np.random.default_rng(0)
    x, w = rng.standard_normal((7, 33)), rng.standard_normal(33)
    mid = evaluate(RMS, {"x": x, "w": w, "eps": 1e-5}, np.float64)["y"]
    want = evaluate(GELU, {"x": mid}, np.float64)["y"]
    assert np.array_equal(evaluate(f, {"x": x, "w": w, "eps": 1e-5}, np.float64)["gelu_y"], want)


def test_refusals():
    with pytest.raises(TairError, match="not an output"):
        fuse(RMS, GELU, {"x": "ms"})
    with pytest.raises(TairError, match="not a tensor parameter"):
        fuse(RMS, GELU, {"z": "y"})
    with pytest.raises(TairError, match="empty"):
        fuse(RMS, GELU, {})
    cast = parse("tair cast(x: bf16[N]) -> (y: f32[N]) {\n y = cast_f32(x)\n}")
    with pytest.raises(TairError, match="bf16"):
        fuse(RMS, cast, {"x": "y"})


@pytest.mark.parametrize("a,b,template", [("rmsnorm", "gelu", "rowwise"), ("layernorm", "gelu", "rowwise"), ("gelu", "cast_bf16", "elementwise")])
def test_fused_manifests_of_corpus_kernels_have_a_template(a, b, template):
    ma, mb = corpus.load(a), corpus.load(b)
    d = fuse_manifests(ma, mb, {"x": "y"})
    m = Manifest.from_dict(d, ma.path)
    assert m.source is None and m.reference.kind == "tair" and gen.applicable(m) == [template]
    outs = m.outputs()
    assert len(outs) == 1 and list(outs[0].shape) == list(ma.outputs()[0].shape) and str(outs[0].dtype) == str(mb.outputs()[0].dtype)
    assert not any(p.name == ma.outputs()[0].name for p in m.params)          # the intermediate tensor is gone
    assert m.tolerance[outs[0].name]["rtol"] >= ma.tolerance_for(ma.outputs()[0].name)[0]
    assert gen.generate(m).module is not None
