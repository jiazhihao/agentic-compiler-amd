"""M8: backend passes for imported code and the default policy."""
import copy
import json

import pytest

from agc import corpus, mir
from agc.mir import abi, check, loops
from conftest import KERNELS, gpu, needs_toolchain

RECORD = corpus.BASELINES.with_name("policy-gfx950.json")


def _import(name):
    from agc.runtime import harness
    return mir.parse(harness.reference_build(corpus.load(name)).asm)


@needs_toolchain
def test_loop_analysis_on_the_corpus():
    k = _import("matvec").kernel()
    (L,) = loops.find_loops(k)
    assert L.label == ".LBB0_3" and str(L.counter) == "s9" and L.exit_label == ".Lft2"
    assert sorted((str(p.reg), p.step, p.vector) for p in L.pointers) == [("s[6:7]", 4, False), ("v[2:3]", 4, True)]
    assert len(L.loads) == 2 and len(L.compute) == 1 and len(L.waits) == 1
    g = loops.find_loops(_import("gemm_naive").kernel())[0]
    strides = {str(p.reg): p.step for p in g.pointers}
    assert strides["v[4:5]"] == 4 and str(strides["v[6:7]"]) == "s[4:5]"            # A is contiguous, B is strided
    # the rowwise loops exit on a per-lane mask: unrolled behind a guard when the mask comes from a per-lane counter
    # alone; a loop that also leaves on the data (a NaN test) is refused
    why = loops.explain(_import("softmax").kernel())
    assert len(why) == 4 and why[".LBB0_7"] == "ok" and sum("one vector compare" in r for r in why.values()) == 3
    (L,) = loops.find_loops(_import("row_sum").kernel())
    assert L.mask["kind"] in ("rising", "countdown") and L.counter is None
    assert "one vector compare" in loops.explain(_import("row_argmax").kernel())[".LBB0_2"]
    assert loops.explain(_import("axpy").kernel()) == {}


@needs_toolchain
@pytest.mark.parametrize("factor", [2, 4, 8, 16])
def test_unroll_loads_structure(factor):
    m = _import("matvec")
    before = sum(1 for _ in m.kernel().insts())
    info = loops.unroll_loads(m.kernel(), factor)
    assert info["loop"] == ".LBB0_3" and info["factor"] == factor and info["bit_identical"]
    k = m.kernel()
    labels = [b.label for b in k.blocks]
    i = labels.index(".Lunroll0")
    assert labels[i - 1] == ".Lpre0" and labels[i + 1] == ".Ltail0" and labels[i + 2] == ".LBB0_3"
    body = [str(x) for x in k.blocks[i].insts]
    fmacs = [x for x in body if x.startswith("v_fmac_f32_e32 v4,")]
    assert len(fmacs) == factor                                                     # one accumulator, original order
    assert body[-1] == "s_cbranch_scc0 .Lunroll0" and f"s_add_i32 s9, s9, -{factor}" in body
    waits = [x for x in body if x.startswith("s_waitcnt")]
    # every load is issued before the first wait; each wide load is then waited for only when its
    # first element is needed (`vmcnt(n)` with n falling to 0)
    assert 1 <= len(waits) <= max(1, factor // 4) and "lgkmcnt(0)" in waits[0] and waits[-1].startswith("s_waitcnt vmcnt(0)")
    assert max(i for i, x in enumerate(body) if "load" in x) < body.index(waits[0])
    if factor >= 4:
        assert sum(x.startswith("global_load_dwordx4") for x in body) == factor // 4
        assert any(x.startswith(f"s_load_dwordx{factor}") for x in body)
    assert [str(x) for x in k.blocks[i + 1].insts] == ["s_cmp_eq_u32 s9, 0", "s_cbranch_scc1 .Lft2"]
    r = check.static_check(m)
    assert r["ok"], [f for f in r["findings"] if f.get("severity") != "warning"]
    assert sum(1 for _ in k.insts()) > before
    plain = _import("matvec")
    loops.unroll_loads(plain.kernel(), 4, wide=False)
    text = mir.print_kernel_body(plain.kernel())
    assert "dwordx4" not in text.split(".Lunroll0:")[1].split(".Ltail0:")[0] and "offset:12" in text


@needs_toolchain
def test_unroll_loads_refusals():
    with pytest.raises(loops.NotApplicable, match="no loop can be unrolled"):
        loops.unroll_loads(_import("row_argmax").kernel(), 4)
    with pytest.raises(loops.NotApplicable, match="no single-block loop"):
        loops.unroll_loads(_import("axpy").kernel(), 4)
    with pytest.raises(loops.NotApplicable, match="factor"):
        loops.unroll_loads(_import("matvec").kernel(), 3)
    with pytest.raises(loops.NotApplicable, match="no block"):
        loops.unroll_loads(_import("matvec").kernel(), 4, loop=".Lnope")
    # a loop whose loaded value is used after the loop must not be transformed
    m = _import("matvec")
    k = m.kernel()
    k.block(".LBB0_5").insts.insert(1, mir.parse_inst("v_add_f32_e32 v4, v4, v5"))
    with pytest.raises(loops.NotApplicable, match="used after the loop"):
        loops.unroll_loads(k, 4, loop=".LBB0_3")


@needs_toolchain
def test_unroll_through_the_session(tmp_path):
    from agc.session import Session, SessionError
    s = Session.open(KERNELS / "gemm_naive.json", tmp_path, quick=True)
    assert "unroll_loads" in s.actions("ref")["transforms"]
    e = s.apply("ref", "unroll_loads", {"factor": 8})
    assert e["action"] == {"name": "unroll_loads", "params": {"factor": 8}} and s.static_check(e["id"])["ok"]
    d = s.asm_diff("ref", e["id"])
    assert d["delta"]["loads"] > 8 and d["registers"]["b"]["vgprs"] > d["registers"]["a"]["vgprs"]
    with pytest.raises(SessionError, match="no loop can be unrolled"):
        Session.open(KERNELS / "row_argmax.json", tmp_path, quick=True).apply("ref", "unroll_loads", {"factor": 4})


def test_recorded_policy_results():
    """`scripts/policy.py`: the default policy on every manifest. A fallback is never counted as a win."""
    rec = json.loads(RECORD.read_text())
    ks = rec["kernels"]
    assert set(corpus.names()) <= set(ks) and "temperature_softmax" in ks
    for name, k in ks.items():
        c = k["chosen"]
        if k["fallback"]:
            assert c["path"] == "amdclang" and c["speedup"] == 1.0 and c["ci95"] is None, name
        elif c.get("ci95"):
            assert c["ci95"][0] > 1.01 and c["path"] in ("import+pass", "generate"), name
            assert c["bit_identical"] == (c["path"] == "import+pass"), name
        assert all(r["outcome"] in ("win", "parity", "loss", "rejected", "no_baseline") for r in k["candidates"]), name
    assert ks["matvec"]["chosen"]["how"].startswith("unroll_loads") and ks["matvec"]["chosen"]["ci95"][0] > 2.0
    assert ks["gemm_naive"]["chosen"]["path"] == "import+pass" and ks["softmax"]["chosen"]["path"] == "generate"
    s = rec["summary"]
    assert s["wins"] + s["fallbacks"] == s["with_baseline"] and s["wins"] >= 9 and s["geomean_without_mfma_gemm"] > 1.2


@pytest.mark.parametrize("name, path, at_least", [pytest.param("matvec", "import+pass", 2.0, marks=gpu),
                                                  pytest.param("transpose", "amdclang", None, marks=gpu)])
def test_default_policy(name, path, at_least, tmp_path):
    from agc.session import Session
    from agc.session.policy import optimize
    s = Session.open(KERNELS / f"{name}.json", tmp_path)
    r = optimize(s)
    assert r["chosen"]["path"] == path and s.resolve("best") == r["chosen"]["state"]
    if at_least:
        assert not r["fallback"] and r["chosen"]["ci95"][0] > at_least and r["chosen"]["bit_identical"]
        assert s.store.get_result(r["chosen"]["state"], "check")["ok"]
    else:                                       # nothing applies: the amdclang build, reported as a fallback
        assert r["fallback"] and r["chosen"]["state"] == s.ref_id and r["chosen"]["speedup"] == 1.0
        assert all(c["outcome"] == "rejected" for c in r["candidates"])


@needs_toolchain
def test_unroll_loads_on_a_counter_that_goes_down_by_two():
    """A loop amdclang unrolled itself (`#pragma unroll 2`) counts down by 2 per iteration."""
    m = _import("matvec")
    k = m.kernel()
    b = k.block(".LBB0_3")
    (i,) = [n for n, x in enumerate(b.insts) if str(x).startswith("s_add_") and str(x).endswith("s9, s9, -1")]
    b.insts[i] = mir.asm.parse_inst(str(b.insts[i]).replace("-1", "-2"))
    (L,) = loops.find_loops(k)
    assert L.trip_step == 2
    loops.unroll_loads(k, 4)
    body = [str(x) for x in k.block(".Lunroll0").insts]
    pre = [str(x) for x in k.block(".Lpre0").insts]
    assert "s_add_i32 s9, s9, -8" in body and "s_cmp_lt_i32 s9, 8" in body and "s_cmp_lt_i32 s9, 8" in pre
    assert check.static_check(m)["ok"]


@needs_toolchain
@pytest.mark.parametrize("factor", [2, 4, 8])
def test_unroll_loads_on_an_exec_mask_loop_runs_behind_a_guard(factor):
    m = _import("row_sum")
    k = m.kernel()
    (L,) = loops.find_loops(k)
    loads = len(L.loads)
    loops.unroll_loads(k, factor)
    labels = [b.label for b in k.blocks]
    i = labels.index(".Ltail0")                                                      # the guard
    assert labels[i - 1] == ".Lpre0" and labels[i + 1] == ".Lunroll0" and labels[i + 2] == L.label
    guard = [str(x) for x in k.blocks[i].insts]
    assert guard[-1] == f"s_cbranch_scc1 {L.label}" and any(x.startswith("v_cmp_") for x in guard)
    body = [str(x) for x in k.blocks[i + 1].insts]
    assert body[-1] == "s_branch .Ltail0"
    assert not any("exec" in x.split()[1] for x in body if x.startswith("s_"))        # EXEC does not change in the unrolled body
    assert sum("global_load" in x for x in body) in (loads * factor, max(1, loads * factor // 4), loads * factor // 2)
    orig = [str(x) for x in k.blocks[i + 2].insts]
    assert orig[-1] == f"s_cbranch_execnz {L.label}"                                 # the original loop finishes
    r = check.static_check(m)
    assert r["ok"], [f for f in r["findings"] if f.get("severity") != "warning"]


@pytest.mark.parametrize("name", [pytest.param(n, marks=gpu) for n in ("row_sum", "rmsnorm", "layernorm")])
def test_unrolled_exec_mask_loops_pass_the_battery(name, tmp_path):
    from agc.session import Session
    s = Session.open(KERNELS / f"{name}.json", tmp_path)
    st = s.apply("ref", "unroll_loads", {"factor": 4})
    assert s.check(st["id"])["ok"]
