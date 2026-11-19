import json

import pytest

from agc.manifest import Manifest, ManifestError, eval_expr
from conftest import KERNELS


def axpy_dict():
    return json.loads((KERNELS / "axpy.json").read_text())


def load(d):
    return Manifest.from_dict(d, KERNELS / "x.json")


def test_load_and_resolve():
    m = Manifest.load(KERNELS / "axpy.json")
    r = m.resolve({"N": 1000})
    assert r.tensors == {"x": (1000,), "y": (1000,)}
    assert r.scalars == {"a": 1.5, "n": 1000}
    assert r.grid == (4, 1, 1) and r.block == (256, 1, 1)
    assert [p.name for p in m.outputs()] == ["y"] and [p.name for p in m.inputs()] == ["x", "y"]
    assert m.timing_symbols() == {"N": 67108864}
    assert m.tolerance_for("y") == (1e-4, 1e-5) and m.cond_for("y") == 4e-7


def test_round_trip():
    m = Manifest.load(KERNELS / "axpy.json")
    assert Manifest.from_dict(m.to_dict(), m.path).to_dict() == m.to_dict()


def test_expressions():
    assert eval_expr("cdiv(N, 256) * 2 + max(1, N % 3)", {"N": 1000}) == 9
    for bad in ("N / 3", "__import__('os')", "M", "N.real", "1 if N else 2"):
        with pytest.raises(ManifestError):
            eval_expr(bad, {"N": 1000})


@pytest.mark.parametrize("edit, message", [
    (lambda d: d.pop("entry"), "missing required field"),
    (lambda d: d["params"][0].update(dtype="f128"), "unknown dtype"),
    (lambda d: d["params"].append(dict(d["params"][0])), "duplicate"),
    (lambda d: d["launch"].update(block=[2048]), "more than 1024"),
    (lambda d: d["launch"].update(grid=["N - N"]), "positive"),
    (lambda d: d.update(dynamic=["M"]), "not in shapes"),
    (lambda d: d.update(source="missing.hip"), "not found"),
    (lambda d: d["reference"].update(kind="magic"), "reference.kind"),
    (lambda d: d.update(tolerance={"x": {"rtol": 1}}), "not an output"),
    (lambda d: d.update(bench_shapes={"Q": 4}), "unknown symbol"),
    (lambda d: (d.pop("source"), d.update(reference={"kind": "none"})), "needs a reference"),
])
def test_rejections(edit, message):
    d = axpy_dict()
    edit(d)
    with pytest.raises(ManifestError, match=message):
        load(d)
