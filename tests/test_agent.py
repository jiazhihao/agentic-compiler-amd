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


def _with_baseline(tmp_path, baseline):
    d = json.loads((KERNELS / "axpy.json").read_text())
    d["source"] = str(KERNELS / "axpy.hip")
    for key in ("reference", "program"):
        if isinstance(d.get(key), dict) and d[key].get("file"):
            d[key]["file"] = str(KERNELS / d[key]["file"])
    d["baseline"] = baseline
    p = tmp_path / "axpy.json"
    p.write_text(json.dumps(d))
    return p


@needs_toolchain
def test_a_manifest_baseline_is_its_own_state_and_what_candidates_are_measured_against(tmp_path):
    (tmp_path / "strong.hip").write_text((KERNELS / "axpy.hip").read_text() + "\n// restructured\n")
    p = _with_baseline(tmp_path, {"source": "strong.hip", "flags": ["-ffast-math"], "launch": {"block": [128], "grid": ["cdiv(N, 128)"]}})
    s = Session.open(p, tmp_path / "root", quick=True)
    plain = Session.open(KERNELS / "axpy.json", tmp_path / "root", quick=True)
    assert s.base_id != s.ref_id and s.id != plain.id and plain.base_id == plain.ref_id
    assert s.store.tags()["baseline"] == s.base_id and s.resolve("baseline") == s.base_id
    assert s.launch_of(s.base_id)["block"] == [128] and s.launch_of(s.ref_id) is None
    assert s.info()["baseline"]["id"] == s.base_id
    with pytest.raises(SessionError):
        s.tag("ref", "baseline")
    from agc.session.policy import candidates
    st = next(c for c in candidates(s) if c["how"].startswith("coarsen"))["make"]()
    assert st["parent"] == s.base_id                                  # the policy works on the baseline, not on `ref`
    assert agent.runner.own_source(s, st["id"]) is None               # the baseline is not the session's own source
    own = s.source((KERNELS / "axpy.hip").read_text() + "\n// mine\n", defines={"EPT": 2}, flags=["-ffast-math"])
    c = agent.runner.own_source(s, own["id"])
    assert c["state"] == own["id"] and c["flags"] == ["-ffast-math"] and c["defines"] == {"EPT": "2"}


def test_a_manifest_baseline_is_validated(tmp_path):
    from agc.manifest import Manifest, ManifestError
    for bad in ({"threads": 4}, {"source": "missing.hip"}, "fast"):
        with pytest.raises(ManifestError, match="baseline"):
            Manifest.load(_with_baseline(tmp_path, bad))


def test_rep_blocks_expand_in_edit_text():
    from agc.session.session import expand
    text = "s_nop 0\n%rep i 2\n  %rep j 4 6\n  v_add_f32 v{8 + 4*i + j}, v{j}, v{i}\n  %end\n%end\ns_endpgm"
    assert expand(text).split("\n") == ["s_nop 0", "  v_add_f32 v12, v4, v0", "  v_add_f32 v13, v5, v0",
                                        "  v_add_f32 v16, v4, v1", "  v_add_f32 v17, v5, v1", "s_endpgm"]
    assert expand("%rep i 0 12 4\nx{i}\n%end") == "x0\nx4\nx8" and expand("%rep i 0\nx\n%end\ny") == "y"
    for bad in ("%rep i 2\nx", "x\n%end", "%rep i 2\nv{k}\n%end", "%rep i\nx\n%end"):
        with pytest.raises(SessionError) as e:
            expand(bad)
        assert e.value.kind == "parse"


@needs_toolchain
def test_edit_replaces_a_run_to_the_end_of_a_block_and_liveness_names_dead_registers(tmp_path):
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    k = s._kernel(s.module("ref"))
    b = k.blocks[0]
    tail = "\n".join(str(i) for i in b.insts[1:])
    st = s.edit("ref", [{"op": "replace", "block": b.label, "index": 1, "count": "end", "text": "%rep i 2\ns_nop {i}\n%end\n" + tail}])
    k2 = s._kernel(s.module(st["id"]))
    assert [str(i) for i in k2.blocks[0].insts[1:3]] == ["s_nop 0", "s_nop 1"]
    assert sum(len(x.insts) for x in k2.blocks) == sum(len(x.insts) for x in k.blocks) + 2
    lv = s.liveness("ref", b.label)["if_vector_writes_cover_all_lanes"]
    named = {int(n) for i in b.insts for n in __import__("re").findall(r"\bv(\d+)\b", str(i))}
    assert lv["dead_across_block"]["v"] and not named & set(lv["dead_across_block"]["v"])


@needs_toolchain
def test_edit_text_may_introduce_labels_and_an_empty_replace_deletes(tmp_path):
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    k = s._kernel(s.module("ref"))
    b = k.blocks[0]
    st = s.edit("ref", [{"op": "insert", "block": b.label, "index": 1, "text": "s_mov_b32 s40, 2\n.Lspin:\ns_sub_u32 s40, s40, 1\ns_cmp_lg_u32 s40, 0\ns_cbranch_scc1 .Lspin"}])
    k2 = s._kernel(s.module(st["id"]))
    labels = [x.label for x in k2.blocks]
    assert ".Lspin" in labels and [str(i) for i in k2.block(".Lspin").insts] == ["s_sub_u32 s40, s40, 1", "s_cmp_lg_u32 s40, 0", "s_cbranch_scc1 .Lspin"]
    assert s.static_check(st["id"])["ok"]
    with pytest.raises(SessionError, match="already exists"):
        s.edit("ref", [{"op": "insert", "block": b.label, "index": 1, "text": f"{k.blocks[-1].label}:\ns_nop 0"}])
    gone = s.edit(st["id"], [{"op": "replace", "block": b.label, "index": 1, "text": ""}])
    assert "s_mov_b32 s40, 2" not in [str(i) for i in s._kernel(s.module(gone["id"])).insts()]


@needs_toolchain
def test_static_check_names_the_nearest_instruction_and_a_scalar_no_path_has_written(tmp_path):
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    k = s._kernel(s.module("ref"))
    b = k.blocks[0]
    st = s.edit("ref", [{"op": "insert", "block": b.label, "index": 0, "text": "v_sub_nc_u32_e32 v9, v0, v0"}])
    (e,) = [x for x in s.static_check(st["id"])["errors"] if "unknown instruction" in x["message"]]
    assert "v_sub_u32" in e["message"]
    st = s.edit("ref", [{"op": "insert", "block": b.label, "index": 0, "text": "s_mov_b32 s40, s41"},
                        {"op": "insert", "block": k.blocks[-1].label, "index": 0, "text": "s_mov_b32 s41, 0"}])
    r = s.static_check(st["id"])
    assert not r["ok"] and any("no path from the entry" in x["message"] for x in r["errors"])
    lazy = s.apply("ref", "fix_waits", {"rewrite": True})
    assert s.static_check(lazy["id"] if "unchanged" not in lazy else "ref")["ok"]
