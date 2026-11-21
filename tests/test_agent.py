"""The session levels the per-kernel harness adds (source, relaunch, adopt, verify) and the harness's bookkeeping."""
import json

import pytest

from agc import agent
from agc.session import Session, SessionError
from conftest import KERNELS, gpu, needs_toolchain


@needs_toolchain
def test_source_level_makes_a_root_state_with_its_own_launch(tmp_path):
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    text = (KERNELS / "axpy.hip").read_text()
    st = s.source(text + "\n// rewritten\n", {"block": [128], "grid": ["cdiv(N, 128)"]}, note="same code, another block")
    assert st["parent"] is None and st["action"]["name"] == "source"
    assert s.launch_of(st["id"])["block"] == [128] and not s.generated(st["id"])
    assert s.static_check(st["id"])["ok"]
    with pytest.raises(SessionError, match="amdclang rejected") as e:
        s.source("this is not HIP")
    assert e.value.kind == "toolchain"
    with pytest.raises(SessionError) as e:
        s.source(text.replace("axpy", "other"))                     # the entry must stay
    assert e.value.kind == "parameter"


@needs_toolchain
def test_launch_is_checked(tmp_path):
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    for bad in ({"grid": ["UNKNOWN"]}, {"grid": [0]}, {"threads": 4}, {"args": [{"dtype": "u32"}]}, {"grid": [1, 1, 1, 1]}):
        with pytest.raises(SessionError) as e:
            s.relaunch("ref", bad)
        assert e.value.kind == "parameter", bad
    st = s.relaunch("ref", {"block": [64]})
    assert s.store.get(st["id"]).ir == s.store.get(s.ref_id).ir and s.launch_of(st["id"])["block"] == [64]


@needs_toolchain
def test_edit_ir_with_appended_launch_arguments_declares_them(tmp_path):
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    k = s._kernel(s.module("ref"))
    before = len(k.metadata[".args"])
    body = Session.listing(k).replace("s_endpgm", "s_nop 0\n  s_endpgm", 1)
    st = s.edit_ir("ref", body, launch={"args": [{"dtype": "u32", "value": "N"}]})
    k2 = s._kernel(s.module(st["id"]))
    assert len(k2.metadata[".args"]) == before + 1 and k2.metadata[".args"][-1][".size"] == 4
    assert st["action"]["arg_offsets"] == [k2.metadata[".args"][-1][".offset"]]


@needs_toolchain
def test_adopt_rebuilds_an_exported_state(tmp_path):
    s = Session.open(KERNELS / "axpy.json", tmp_path / "a", quick=True)
    st = s.apply("ref", "coarsen", {"factor": 2})
    ex = s.export(st["id"])
    t = Session.open(KERNELS / "axpy.json", tmp_path / "b", quick=True)
    a = t.adopt(ex["asm"], ex["launch"], ex["strict"])
    assert t.store.get(a["id"]).ir == ex["asm"] and t.launch_of(a["id"]) == ex["launch"]
    assert t.static_check(a["id"])["ok"]


@pytest.mark.parametrize("factor", [pytest.param(4, marks=gpu)])
def test_verify_reruns_everything_and_record_writes_a_recipe(factor, tmp_path, monkeypatch):
    s = Session.open(KERNELS / "axpy.json", tmp_path)
    st = s.apply("ref", "coarsen", {"factor": factor})
    v = s.verify(st["id"])
    assert v["ok"] and v["stage"] == "bench" and v["cases"] > 1 and v["outcome"] in ("win", "parity", "loss")
    monkeypatch.setattr(agent.runner, "RECIPES", tmp_path / "recipes")
    d = agent.record(s, st["id"], v, {"summary": "coarsen", "friction": ["none"]}, {"seconds": 0})
    recipe = json.loads((d / "recipe.json").read_text())
    assert recipe["launch"]["args"] and recipe["path"] == ["import", "coarsen"] and (d / "best.s").read_text().startswith("\t.amdgcn_target")


@needs_toolchain
def test_edit_inserts_at_the_end_of_a_block_and_deletes_a_run(tmp_path):
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    k = s._kernel(s.module("ref"))
    last = k.blocks[-1]
    st = s.edit("ref", [{"op": "insert", "block": k.blocks[0].label, "index": 0, "text": "s_nop 0\ns_nop 0\ns_nop 0"}])
    k2 = s._kernel(s.module(st["id"]))
    st2 = s.edit(st["id"], [{"op": "delete", "block": k2.blocks[0].label, "index": 0, "count": 2}])
    assert [str(i) for i in s._kernel(s.module(st2["id"])).blocks[0].insts][0] == "s_nop 0"
    assert len(s._kernel(s.module(st2["id"])).blocks[0].insts) == len(k.blocks[0].insts) + 1
    with pytest.raises(SessionError, match="runs past"):
        s.edit("ref", [{"op": "delete", "block": last.label, "index": 0, "count": len(last.insts) + 1}])


@needs_toolchain
def test_source_sweeps_reuse_the_text_and_defines_reach_the_launch(tmp_path):
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    text = "#ifndef BLK\n#define BLK 256\n#endif\n" + (KERNELS / "axpy.hip").read_text()
    a = s.source(text, {"block": ["BLK"], "grid": ["cdiv(N, BLK)"]}, defines={"BLK": 128})
    assert s.launch_of(a["id"])["block"] == ["(128)"]
    b = s.source(like=a["id"], defines={"BLK": 64})
    assert s.launch_of(b["id"])["grid"] == ["cdiv(N, (64))"] and b["action"]["sha"] == a["action"]["sha"]
    with pytest.raises(SessionError, match="three or more"):
        s.source(text, defines={"NB": 4})
    with pytest.raises(SessionError, match="does not come from"):
        s.source(like="ref", defines={"BLK": 64})
