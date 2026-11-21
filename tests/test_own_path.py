"""agc's own lowering from HIP (roadmap phase 2, M11): kir, the frontend, wave lowering, selection,
the plan of decisions. The CPU tests lower the frontend's recorded output (`tests/kir/*.kir`), so
they need neither Clang nor a GPU."""
import json
from pathlib import Path

import numpy as np
import pytest

from agc import corpus
from agc.kir import IRError, parse_func, print_func, verify
from agc.kir.interp import InterpError, run as run_kir
from agc.kir.passes import contract, simplify, unroll_constant_loops, widen_indices
from agc.lower import LowerError, PlanError, lower_kir
from agc.lower.checks import cpu_check
from agc.manifest import Manifest
from agc.mir import asm, check as mircheck
from agc.wir import ops as wops
from agc.wir.interp import run as run_wir
from agc.wir import assert_ok as wir_ok
from conftest import gpu, needs_toolchain

KIR = Path(__file__).parent / "kir"
LLM = Path(__file__).parent.parent / "bench" / "llm"
OWN = Path(__file__).parent / "own"                    # control-flow kernels written for the lowering
LOWERED = ["axpy", "cast_bf16", "gemm_bf16", "gemm_naive", "gemm_tiled", "matvec", "mo_rope_fwd", "rb_axpy", "rb_copy", "rb_ger",
           "rb_rot", "rb_scal", "rb_swap", "row_sum", "transpose"]     # pass the battery through the own path (own-gfx950.json)
CONTROL = ["divmod", "first_below", "halvings", "last_above", "sum_positive"]


def manifest(name: str) -> Manifest:
    return Manifest.load(next(d / f"{name}.json" for d in (corpus.CORPUS_DIR, LLM, OWN) if (d / f"{name}.json").exists()))


def lowered(name: str, overrides=None):
    return lower_kir(parse_func((KIR / f"{name}.kir").read_text()), overrides)


def body(r) -> str:
    return "\n".join(str(i) for b in r.module.kernels[0].blocks for i in b.insts)


# ---- kir -----------------------------------------------------------------------------------------
LOOP = """kir func f(%y: ptr<i32>, %n: i32) {
  %t: u32 = tid.x
  %i: i64 = cast %t
  loop @loop0 {
    carry %j: i32 = 0:i32, %j2 -> %jend
    carry %s: i32 = 0:i32, %s2 -> %total
    %ti: i32 = cast %t
    %more: i1 = lt %j, %ti
    while %more
    %s2: i32 = add %s, %j
    %j2: i32 = add %j, 1:i32
  }
  %p: ptr<i32> = gep %y, %i
  store %p, %total
}
"""


def test_kir_text_round_trip_and_loop_semantics():
    f = parse_func(LOOP)
    assert verify(f) == []
    assert print_func(parse_func(print_func(f))) == print_func(f)
    y = np.zeros(8, dtype=np.int32)
    run_kir(f, {"y": y, "n": 0}, (1,), (8,))
    assert y.tolist() == [0, 0, 1, 3, 6, 10, 15, 21]            # each thread leaves the loop on its own


def test_kir_fixtures_round_trip():
    for p in sorted(KIR.glob("*.kir")):
        f = parse_func(p.read_text())
        assert verify(f) == [], p.name
        assert print_func(f) == p.read_text(), p.name


@pytest.mark.parametrize("text, message", [
    ("kir func f(%a: i32) {\n  %b: i32 = add %a, %c\n}\n", "used before it is defined"),
    ("kir func f(%a: i32, %x: f32) {\n  %b: i32 = add %a, %x\n}\n", "different types"),
    ("kir func f(%a: i32) {\n  %b: f32 = add %a, %a\n}\n", "result is f32"),
    ("kir func f(%a: i32) {\n  if %a {\n  }\n}\n", "not i1"),
    ("kir func f(%p: ptr<f32>, %a: i32) {\n  store %p, %a\n}\n", "element type"),
])
def test_kir_verifier_refuses(text, message):
    try:
        found = verify(parse_func(text))
    except IRError as e:
        found = [{"message": str(e)}]
    assert any(message in x["message"] for x in found), found


def test_region_values_do_not_escape():
    text = "kir func f(%a: i32, %c: i1) {\n  if %c {\n    %b: i32 = add %a, %a\n  }\n  %d: i32 = add %b, %a\n}\n"
    assert any("not defined" in x["message"] for x in verify(parse_func(text)))


def test_c_semantics_of_integer_division_and_casts():
    f = parse_func("""kir func f(%y: ptr<i32>, %a: i32, %b: i32, %x: f32) {
  %q: i32 = div %a, %b
  %r: i32 = rem %a, %b
  %t: i32 = cast %x
  %p1: ptr<i32> = gep %y, 1:i64
  %p2: ptr<i32> = gep %y, 2:i64
  store %y, %q
  store %p1, %r
  store %p2, %t
}
""")
    y = np.zeros(3, dtype=np.int32)
    run_kir(f, {"y": y, "a": -7, "b": 2, "x": -2.75}, (1,), (1,))
    assert y.tolist() == [-3, -1, -2]                           # truncation toward zero, as C


def test_interpreter_reports_out_of_bounds():
    f = parse_func("kir func f(%y: ptr<f32>) {\n  %t: u32 = tid.x\n  %i: i64 = cast %t\n  %p: ptr<f32> = gep %y, %i\n"
                   "  store %p, 1.0:f32\n}\n")
    with pytest.raises(InterpError, match="out of bounds"):
        run_kir(f, {"y": np.zeros(4, dtype=np.float32)}, (1,), (8,))


def test_passes_unroll_contract_and_no_wrap_indices():
    f = parse_func((KIR / "rb_scal.kir").read_text())
    assert "loop" in print_func(f)
    unroll_constant_loops(simplify(f))
    assert "loop" not in print_func(f)                          # `for (j = 0; j < 2; ++j)` is two iterations
    widen_indices(f)
    t = print_func(f)
    assert "gep %x" in t and "1:i64" in t                        # x[tid + 1]: the same index, one element further
    g = contract(simplify(parse_func((KIR / "axpy.kir").read_text())))
    assert " fma " in print_func(g) and " mul " not in print_func(g).split("if ")[1]


# ---- lowering ------------------------------------------------------------------------------------
@pytest.mark.parametrize("name", LOWERED + CONTROL)
def test_lowering_is_checked_on_the_cpu(name):
    m, r = manifest(name), lowered(name)
    chk = cpu_check(m, r)
    assert chk["ok"] and len(chk["cases"]) >= 4, [c for c in chk["cases"] if not c["ok"]][:1]
    st = mircheck.static_check(r.module, encode=False, strict=True)
    assert st["ok"], [f for f in st["findings"] if f.get("severity") != "warning"][:2]
    assert wir_ok(parse_func(r.wir)) is not None      # the wir text is the program


def test_plan_records_every_decision_and_overrides_change_the_code():
    r = lowered("rb_scal")
    taken = {(e["site"], e["decision"]) for e in r.plan}
    assert ("kernel", "fp.contract") in taken and ("if0", "branch.skip_empty") in taken
    assert any(d == "access.width" for _, d in taken)
    assert all(e["by"] == "default" and e["chosen"] == e["default"] for e in r.plan)
    assert "global_load_dwordx2" in body(r) and "s_cbranch_execz" in body(r)
    single = lowered("rb_scal", {"access.width": 1})
    assert "global_load_dwordx2" not in body(single) and body(single).count("global_load_dword ") == 3
    assert cpu_check(manifest("rb_scal"), single)["ok"]
    one_site = lowered("rb_scal", {"if1.branch.skip_empty": "none"})
    assert body(one_site).count("s_cbranch_execz") == body(r).count("s_cbranch_execz") - 1
    assert [e for e in one_site.plan if e["by"] == "override"] == [e for e in one_site.plan if e["site"] == "if1" and e["decision"] == "branch.skip_empty"]
    off = lowered("axpy", {"fp.contract": "off"})
    assert "v_fmac_f32" in body(lowered("axpy")) and "v_fmac_f32" not in body(off) and "v_mul_f32" in body(off)


def test_loop_decisions_put_several_iterations_loads_in_flight():
    m, r = manifest("matvec"), lowered("matvec")
    assert ("loop0", "loop.unroll") in {(e["site"], e["decision"]) for e in r.plan}
    assert any(e["decision"] == "load.uniform" and e["chosen"] == "scalar" for e in r.plan)
    b = body(r)
    assert "s_load_dword " in b and "s_cbranch_scc1" in b           # x[j] is one scalar load; the loop tests at the bottom
    assert b.count("s_waitcnt vmcnt(0)") == 1
    fast = lowered("matvec", {"loop.unroll": 4, "loop.inflight": "first"})
    fb = body(fast)
    assert "global_load_dwordx4" in fb and "s_load_dwordx4" in fb    # four iterations' data under one wait
    assert fb.count("v_fmac_f32") + fb.count("v_fma_f32") == 5       # four in the main loop, one in the remainder
    assert cpu_check(m, fast)["ok"]
    assert mircheck.static_check(fast.module, encode=False, strict=True)["ok"]
    wide = lowered("matvec", {"loop.unroll": 16, "loop.inflight": "first"})
    assert "s_load_dwordx16" in body(wide) and body(wide).count("global_load_dwordx4") == 4 and cpu_check(m, wide)["ok"]
    with pytest.raises(PlanError, match="not an alternative"):
        lowered("matvec", {"loop.unroll": 3})
    strided = lowered("gemm_naive", {"loop.unroll": 4, "loop.inflight": "first"})      # B is read down a column
    assert cpu_check(manifest("gemm_naive"), strided)["ok"] and "global_load_dwordx4" in body(strided)
    vec = lowered("matvec", {"load.uniform": "vector"})
    assert "s_load_dword " not in body(vec).split("s_waitcnt lgkmcnt(0)", 1)[1] and cpu_check(m, vec)["ok"]


def test_counted_loops_and_why_others_are_not():
    from agc.kir import loops
    from agc.kir.ir import Loop
    from agc.lower import normalize, Plan
    f = normalize(parse_func((KIR / "matvec.kir").read_text()), Plan({}))
    lp = next(s for s in f.walk() if isinstance(s, Loop))
    c = loops.counted(lp)
    assert isinstance(c, loops.Counted) and (c.start, c.step) == (0, 1)
    g = parse_func(LOOP)
    reason = loops.counted(next(s for s in g.walk() if isinstance(s, Loop)))
    assert isinstance(reason, str) and "changes inside the loop" in reason
    h = normalize(parse_func((KIR / "first_below.kir").read_text()), Plan({}))
    assert not any(e["decision"] == "loop.unroll" for e in lower_kir(parse_func((KIR / "first_below.kir").read_text())).plan)
    assert isinstance(loops.counted(next(s for s in h.walk() if isinstance(s, Loop))), str)
    # a counter that starts at the thread's index and a bound offset by it are counted too
    assert any(e["decision"] == "loop.unroll" for e in lowered("row_sum").plan)
    assert any(e["decision"] == "loop.unroll" for e in lowered("rb_ger").plan)


def test_scalar_loads_need_the_empty_mask_branch():
    with pytest.raises(LowerError, match="empty-mask branch"):
        lowered("matvec", {"branch.skip_empty": "none"})
    ok = lowered("matvec", {"branch.skip_empty": "none", "load.uniform": "vector"})
    assert cpu_check(manifest("matvec"), ok)["ok"]


def test_control_flow_becomes_masks():
    r = lowered("first_below")
    assert "break" not in r.kir and "loop @loop0" in r.kir          # the flag of the break is a carried condition
    b = body(r)
    assert "s_cbranch_execnz" in b and "s_or_b64 exec, exec" in b    # lanes leave one by one; the mask is restored
    assert "do" not in lowered("halvings").kir.split("{", 1)[1].split()[0:1]


def test_shared_memory_and_barriers():
    r = lowered("row_sum")
    assert "shared[name=" in r.kir and "barrier" in r.kir and "region[name=" in r.wir
    b = body(r)
    assert "ds_write_b32" in b and "ds_read_b32" in b and b.count("s_barrier") == 10       # 1 + 8 levels + 1
    assert r.module.kernels[0].descriptor["group_segment_fixed_size"] == 1024             # the LDS size is derived
    g = lowered("gemm_tiled")
    assert "ds_read_b128" in body(g) and g.module.kernels[0].descriptor["group_segment_fixed_size"] == 2048
    assert any(e["decision"] == "order.loads" and e["chosen"] == "first" for e in g.plan)


def test_reduce_form_replaces_the_tree_by_dpp():
    m = manifest("row_sum")
    tree = lowered("row_sum")
    assert [(e["site"], e["chosen"], e["alternatives"]) for e in tree.plan if e["decision"] == "reduce.form"] == \
        [("reduce0", "lds_tree", ["lds_tree", "dpp"])]
    r = lowered("row_sum", {"reduce.form": "dpp"})
    assert "wgreduce[op=add, size=256]" in r.kir and "lane.reduce[op=add]" in r.wir
    b = body(r)
    assert b.count("v_add_f32_dpp") == 4 and b.count("v_readlane_b32") == 4 and b.count("s_barrier") == 1
    assert len(b.splitlines()) < len(body(tree).splitlines()) // 2
    assert cpu_check(m, r)["ok"]                         # kir and wir combine in the same order, bit for bit
    assert mircheck.static_check(r.module, encode=False, strict=True)["ok"]
    both = lowered("row_sum", {"reduce.form": "dpp", "loop.unroll": 4})        # the column loop starts at the thread index
    assert cpu_check(m, both)["ok"] and body(both).count("global_load_dword") == 5
    assert not any(e["decision"] == "reduce.form" for e in lowered("gemm_tiled").plan)


def test_wave_reduce_order_is_the_dpp_order():
    from agc.kir.idioms import wave_reduce, workgroup_reduce
    x = np.arange(128, dtype=np.float32).reshape(2, 64) * np.float32(1.1)
    assert np.allclose(wave_reduce(x, "add"), x.sum(axis=1), rtol=1e-6)
    assert wave_reduce(x, "max").tolist() == x.max(axis=1).tolist()
    y = np.random.default_rng(0).standard_normal(512).astype(np.float32)
    out = workgroup_reduce(y, "add", 256)
    assert out.shape == (512,) and len(set(out[:256].tolist())) == 1 and np.isclose(out[0], y[:256].sum(), rtol=1e-5)


def test_integer_division_is_exact():
    from agc.kir.passes import expand_division
    rng = np.random.default_rng(1)
    n = 1 << 12
    a = rng.integers(-2 ** 31, 2 ** 31, n, dtype=np.int64).astype(np.int32)
    b = rng.integers(-2 ** 31, 2 ** 31, n, dtype=np.int64).astype(np.int32)
    b[b == 0] = 7
    a[:6] = [0, 1, -1, 2 ** 31 - 1, -2 ** 31, -2 ** 31]
    b[:6] = [1, 1, 1, 1, 1, 3]
    b[100:200] = rng.integers(1, 50, 100)
    src = ("kir func f(%o: ptr<TY>, %a: ptr<TY>, %b: ptr<TY>) {\n  %t: u32 = tid.x\n  %i: i64 = cast %t\n  %pa: ptr<TY> = gep %a, %i\n"
           "  %pb: ptr<TY> = gep %b, %i\n  %x: TY = load %pa\n  %y: TY = load %pb\n  %q: TY = OP %x, RHS\n  %po: ptr<TY> = gep %o, %i\n"
           "  store %po, %q\n}\n")
    for ty, dt in (("i32", np.int32), ("u32", np.uint32)):
        for op in ("div", "rem"):
            for rhs in ("%y", f"7:{ty}", f"16:{ty}", f"641:{ty}", f"1000003:{ty}") + ((f"-13:{ty}",) if ty == "i32" else (f"4000000007:{ty}",)):
                text = src.replace("TY", ty).replace("OP", op).replace("RHS", rhs)
                exact, expanded = parse_func(text), expand_division(parse_func(text))
                assert verify(expanded) == [] and f" {op} " not in print_func(expanded)
                o1, o2 = np.zeros(n, dt), np.zeros(n, dt)
                run_kir(exact, {"o": o1, "a": a.view(dt).copy(), "b": b.view(dt).copy()}, (n // 256,), (256,))
                run_kir(expanded, {"o": o2, "a": a.view(dt).copy(), "b": b.view(dt).copy()}, (n // 256,), (256,))
                assert np.array_equal(o1, o2), (ty, op, rhs)


def test_safety_gates_catch_missing_barriers():
    from agc.wir import safety
    total = caught = 0
    for name, ov in (("row_sum", {}), ("row_sum", {"reduce.form": "dpp"}), ("gemm_tiled", {})):
        r = lowered(name, ov)
        assert safety(r.wir_func) == []
        lines = r.wir.splitlines()
        for i in [k for k, ln in enumerate(lines) if ln.strip() == "barrier"]:
            total += 1
            caught += bool(safety(parse_func("\n".join(lines[:i] + lines[i + 1:]) + "\n")))
    # the two not caught: the barrier after the last read of row_sum's tree (nothing follows it), and the one
    # in gemm_tiled that keeps the next tile's stores behind this tile's reads (a write after a read, which the
    # gate does not model)
    assert (total, caught) == (13, 11)
    bad = parse_func("""wir func f() {
  %n: u i32 = arg[offset=0, size=4]
  %lane: v u32 = lane.x
  %li: v i32 = bitcast %lane
  loop @loop0 {
    carry %j: v i32 = %li, %j2 -> %jend
    %more: v i1 = lt %j, %n
    while %more
    barrier
    %j2: v i32 = add %j, 64:i32
  }
}
""")
    assert any("different number of times" in x["message"] for x in safety(bad))
    with pytest.raises(IRError, match="different number of times"):
        wir_ok(bad)


def test_plan_refuses_unknown_decisions_and_alternatives():
    with pytest.raises(PlanError, match="no such decision"):
        lowered("axpy", {"if7.branch.skip_empty": "none"})
    with pytest.raises(PlanError, match="not an alternative"):
        lowered("axpy", {"fp.contract": "sometimes"})


def test_lowered_axpy_matches_amdclang_in_shape():
    b = body(lowered("axpy"))
    assert "v_fmac_f32_e32" in b and "s_and_saveexec_b64" in b and b.strip().endswith("s_endpgm")
    assert b.count("global_load_dword") == 2 and b.count("global_store_dword") == 1
    assert len(b.splitlines()) <= 23                            # amdclang: 21


def test_a_loop_each_thread_leaves_on_its_own_is_lowered_under_a_mask():
    r = lower_kir(parse_func(LOOP))
    b = body(r)
    assert "s_and_b64 exec, exec" in b and "s_cbranch_execz" in b and "s_or_b64 exec, exec" in b
    w = parse_func(r.wir)
    y = np.zeros(8, dtype=np.int32)
    run_wir(w, (1,), (8,), {0: y, 8: 0})
    assert y.tolist() == [0, 0, 1, 3, 6, 10, 15, 21]
    assert mircheck.static_check(r.module, encode=False, strict=True)["ok"]


def test_wir_interpreter_checks_uniformity():
    w = parse_func("""wir func f() {
  %y: u ptr<u32> = arg[offset=0, size=8]
  %lane: v u32 = lane.x
  %wg: u u32 = wg.x
  %first: u u32 = mul %wg, 64:u32
  %k: v u32 = add %first, %lane
  %i: v i64 = cast %k
  store[scale=4, off=0] %y, %i, %wg
}
""")
    wir_ok(w)
    y = np.zeros(128, dtype=np.uint32)
    run_wir(w, (2,), (64,), {0: y})
    assert y[:64].tolist() == [0] * 64 and y[64:].tolist() == [1] * 64
    wrong = parse_func("""wir func f() {
  %lane: v u32 = lane.x
  %u: u u32 = add %lane, 1:u32
}
""")
    with pytest.raises(IRError, match="uniform result from a per-lane operand"):
        wir_ok(wrong)
    with pytest.raises(IRError, match="lane mask"):
        wir_ok(parse_func("wir func f() {\n  %n: u i32 = arg[offset=0, size=4]\n  %c: u i1 = lt %n, 4:i32\n  where %c {\n  }\n}\n"))


def test_own_path_record_is_consistent():
    rec = json.loads((corpus.BASELINES.with_name("own-gfx950.json")).read_text())
    passed = sorted(n for n, k in rec["kernels"].items() if k["stage"] == "battery")
    assert set(LOWERED) <= set(passed)
    for n in passed:
        k = rec["kernels"][n]
        # gemm_tiled: amdclang leaves that multiply and add unfused; `fp.contract: off` is bit-identical (a GPU test)
        assert (k["bit_identical"] is True or n == "gemm_tiled") and k["battery"].split("/")[0] == k["battery"].split("/")[1], n
    assert rec["summary"]["battery_ok"] == len(passed)


# ---- with Clang ----------------------------------------------------------------------------------
@needs_toolchain
def test_frontend_reproduces_the_fixtures():
    from agc.frontend import lower_hip
    for p in sorted(KIR.glob("*.kir")):
        m = manifest(p.stem)
        assert print_func(lower_hip(m.source, m.entry, flags=m.hip_flags)) == p.read_text(), p.stem


@needs_toolchain
def test_frontend_lists_everything_unsupported():
    from agc.frontend import FrontendError, lower_hip
    with pytest.raises(FrontendError) as e:
        lower_hip(OWN / "unsupported.hip", "refused")
    whats = " | ".join(u["what"] for u in e.value.items)
    assert "float[4]" in whats and "SwitchStmt" in whats and "GotoStmt" in whats        # every construct, not the first one
    assert all(u["loc"] != "?" for u in e.value.items) and {u["loc"].split(":")[0] for u in e.value.items} >= {"6", "7", "11"}


@needs_toolchain
@pytest.mark.parametrize("name", LOWERED)
def test_lowered_modules_assemble(name):
    assert mircheck.static_check(lowered(name).module, strict=True)["ok"]


# ---- on the device -------------------------------------------------------------------------------
@pytest.mark.parametrize("marks", [pytest.param(None, marks=gpu)])
def test_control_flow_kernels_pass_the_battery(marks, agc_root):
    from agc.session import Session
    for name in CONTROL:
        s = Session.open(OWN / f"{name}.json", agc_root)
        st = s.lower()
        ck = s.check(st["id"])
        assert ck["ok"] and ck["cases_run"] == ck["cases_total"], (name, ck)


@pytest.mark.parametrize("marks", [pytest.param(None, marks=gpu)])
def test_loop_decisions_beat_amdclang_bit_identically(marks, agc_root):
    from agc.session import Session
    s = Session.open(corpus.CORPUS_DIR / "matvec.json", agc_root)
    base = s.lower()
    fast = s.replan(base["id"], {"loop.unroll": 16, "loop.inflight": "first"})
    assert s.check(fast["id"])["ok"] and s.equivalent(fast["id"], "ref")["bit_identical"]
    b = s.bench(fast["id"])
    assert b["outcome"] == "win" and b["speedup_ci95"][0] > 2.0, b
    assert s.explain(fast["id"], "loop0")["decisions"][0]["chosen"] == 16


@pytest.mark.parametrize("marks", [pytest.param(None, marks=gpu)])
def test_reduction_and_loop_decisions_on_row_sum(marks, agc_root):
    from agc.session import Session
    s = Session.open(corpus.CORPUS_DIR / "row_sum.json", agc_root)
    base = s.lower()
    assert s.check(base["id"])["ok"] and s.equivalent(base["id"], "ref")["bit_identical"]
    dpp = s.replan(base["id"], {"reduce.form": "dpp"})
    eq = s.equivalent(dpp["id"], "ref")
    assert s.check(dpp["id"])["ok"] and eq["within_tolerance"] and not eq["bit_identical"]      # another order of additions
    fast = s.replan(base["id"], {"loop.unroll": 4})
    assert s.check(fast["id"])["ok"] and s.equivalent(fast["id"], "ref")["bit_identical"]
    b = s.bench(fast["id"])
    assert b["outcome"] == "win" and b["speedup_ci95"][0] > 1.15, b


@pytest.mark.parametrize("name", ["axpy", "rb_scal", "gemm_naive", "gemm_tiled"])
@pytest.mark.parametrize("marks", [pytest.param(None, marks=gpu)])
def test_own_path_passes_the_battery_and_equals_amdclang(name, marks, agc_root):
    from agc.session import Session
    p = corpus.CORPUS_DIR / f"{name}.json"
    s = Session.open(p if p.exists() else LLM / f"{name}.json", agc_root)
    st = s.lower({"fp.contract": "off"} if name == "gemm_tiled" else None)     # amdclang does not contract in gemm_tiled
    assert s.static_check(st["id"])["ok"]
    ck = s.check(st["id"])
    assert ck["ok"] and ck["cases_run"] == ck["cases_total"]
    assert s.equivalent(st["id"], "ref")["bit_identical"]


@pytest.mark.parametrize("marks", [pytest.param(None, marks=gpu)])
def test_session_lower_plan_replan(marks, agc_root):
    from agc.session import Session, SessionError
    s = Session.open(LLM / "rb_scal.json", agc_root)
    a = s.lower()
    plan = s.plan(a["id"])
    assert plan["overrides"] == {} and all("doc" in d for d in plan["decisions"])
    b = s.replan(a["id"], {"access.width": 1})
    assert b["id"] != a["id"] and b["overridden"] and s.check(b["id"])["ok"]
    assert "load[" in s.ir(b["id"], "wir")["text"] and "kir func" in s.ir(b["id"], "kir")["text"]
    back = s.replan(b["id"], {"access.width": 4})                  # the default again: the first state
    assert back["id"] == a["id"]
    with pytest.raises(SessionError) as e:
        s.replan(a["id"], {"if9.branch.skip_empty": "none"})
    assert e.value.kind == "parameter"
    with pytest.raises(SessionError):
        s.plan("ref")
