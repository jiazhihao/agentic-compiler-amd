"""M6: tensor programs in, binaries out. tair, the virtual-register builder, checker-driven wait and
hazard insertion, the elementwise and rowwise templates, and generation through the session."""
import importlib.util
import json
from pathlib import Path

import numpy as np
import pytest

from agc.runtime.timing import PROTOCOL_VERSION

from agc import corpus, gen, mir, tair
from agc.gen.builder import Builder, GenError
from agc.manifest import Manifest
from agc.mir import abi, check, hazards, passes, waitcnt
from conftest import KERNELS, gpu, needs_toolchain

PROGRAMS = [n for n in corpus.names() if corpus.load(n).program]
TENSOR = Path(__file__).parent / "tensor" / "temperature_softmax.json"


def _refs():
    spec = importlib.util.spec_from_file_location("corpus_refs", KERNELS / "refs.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# ---- tair ----------------------------------------------------------------------------------
def test_tair_text_and_errors():
    p = tair.parse((KERNELS / "softmax.tair").read_text())
    assert p.name == "softmax" and [s.reduce for s in p.body] == ["max", "sum", None]
    assert tair.parse(tair.print_program(p)) == p
    assert p.ranks() == {"x": "full", "m": "row", "s": "row", "y": "full"}
    q = tair.parse("tair f(x: f32[N], a: f32) -> (y: f32[N]) {\n  y = -x * (a + 2) / 4 - max(x, 0.5)   # comment\n}")
    assert tair.print_program(q).splitlines()[1] == "  y = neg(x) * (a + 2.0) / 4.0 - max(x, 0.5)"
    for bad, msg in [("tair f(x: f32[N]) -> (y: f32[N]) {\n  y = z + 1\n}", "not defined"),
                     ("tair f(x: f32[N]) -> (y: f32[N]) {\n  y = frob(x)\n}", "unknown function"),
                     ("tair f(x: f32[N]) -> (y: f32[N]) {\n  y = max(x)\n}", "takes 2"),
                     ("tair f(x: f32[N]) -> (y: f32[N]) {\n  t = x\n}", "never assigned"),
                     ("tair f(x: f32[N]) -> (y: f32[N]) {\n  y = reduce prod(x)\n}", "unknown reduction"),
                     ("func f() {}", "expected")]:
        with pytest.raises(tair.TairError, match=msg):
            tair.parse(bad)


def test_tair_interpreter_agrees_with_the_python_references():
    """Two independent definitions of every corpus program."""
    refs = _refs()
    rng = np.random.default_rng(0)
    x = rng.standard_normal((7, 33)).astype(np.float32)
    w, b = rng.standard_normal(33).astype(np.float32), rng.standard_normal(33).astype(np.float32)
    cases = {"axpy": (dict(x=x[0], y=x[1], a=1.5), lambda: refs.axpy(x[0], x[1], 1.5, 33)["y"]),
             "gelu": (dict(x=x[0]), lambda: refs.gelu(x[0], 33)),
             "row_sum": (dict(x=x), lambda: refs.row_sum(x, 7, 33)),
             "softmax": (dict(x=x), lambda: refs.softmax(x, 7, 33)),
             "rmsnorm": (dict(x=x, w=w, eps=1e-5), lambda: refs.rmsnorm(x, w, 1e-5, 7, 33)),
             "layernorm": (dict(x=x, g=w, b=b, eps=1e-5), lambda: refs.layernorm(x, w, b, 1e-5, 7, 33))}
    for name, (args, ref) in cases.items():
        p = tair.parse((KERNELS / f"{name}.tair").read_text())
        out = next(iter(tair.evaluate(p, args, np.float64).values()))
        assert np.allclose(out, ref(), rtol=1e-6, atol=1e-7), name
    y = tair.evaluate(tair.parse((KERNELS / "cast_bf16.tair").read_text()), dict(x=x[0]))["y"]
    assert y.dtype.name == "bfloat16" and set(PROGRAMS) == set(cases) | {"cast_bf16", "gemm_bf16"}


# ---- builder and passes --------------------------------------------------------------------
def test_builder_allocates_and_legalizes():
    b = Builder("k")
    ptr = b.s(2)
    b.emit("s_load_dwordx2", ptr, "s[0:1]", 0)
    one, quad, pair = b.v(), b.v(4), b.v(2)
    b.emit("v_mov_b32_e32", b.part(pair, 1), 0)
    b.emit("v_lshlrev_b32_e32", b.part(pair, 0), 4, "v0")
    b.emit("v_lshl_add_u64", pair, ptr, 0, pair)
    b.emit("global_load_dwordx4", quad, pair, "off")
    b.emit("v_exp_f32_e32", one, b.part(quad, 0))
    b.emit("v_add_f32_e32", one, one, b.part(quad, 3))
    b.emit("global_store_dword", pair, one, "off")
    b.emit("s_endpgm")
    k = b.finish([abi.Arg("global_buffer")])
    text = mir.print_kernel_body(k)
    assert "%" not in text
    regs = [o for i in k.insts() for o in i.operands if isinstance(o, mir.Reg) and o.count > 1 and o.cls == "v"]
    assert regs and all(r.index % 2 == 0 for r in regs)                      # tuples start on even registers
    assert all(not (r.cls == "v" and r.index == 0 and r.count > 1) for r in regs)     # v0 (the workitem id) is not reused
    lines = text.splitlines()
    # the load of the pointer is waited for at its first use, the vector load at its first use,
    # and the transcendental's result gets its wait state: all inserted by the checker-driven passes
    assert lines[lines.index("\tv_lshl_add_u64 " + lines[[l.split()[0] for l in lines].index("v_lshl_add_u64")].split(" ", 1)[1]) - 1] == "\ts_waitcnt lgkmcnt(0)"
    i = [l.split()[0] for l in lines].index("v_exp_f32_e32")
    assert lines[i - 1] == "\ts_waitcnt vmcnt(0)" and lines[i + 1] == "\ts_nop 0"
    assert check.static_check(abi.make_module([k]), encode=False)["ok"]
    with pytest.raises(GenError, match="unknown virtual"):
        bad = Builder("k")
        bad.emit("v_mov_b32_e32", mir.Reg("v", 0, 1, name="ghost"), 0)
        bad.finish([])


def test_allocation_across_a_loop_and_exhaustion():
    b = Builder("k")
    acc, tmp, cnt = b.v(), b.v(), b.s()
    b.emit("v_mov_b32_e32", acc, 0)
    b.emit("s_mov_b32", cnt, 8)
    loop = b.label()
    b.emit("v_mov_b32_e32", tmp, 1.0)                       # dead after the next instruction ...
    b.emit("v_add_f32_e32", acc, tmp, acc)
    other = b.v()
    b.emit("v_mov_b32_e32", other, 2.0)                     # ... so `other` may reuse its register, but never acc's
    b.emit("v_add_f32_e32", acc, other, acc)
    b.emit("s_sub_u32", cnt, cnt, 1)
    b.emit("s_cmp_eq_u32", cnt, 0)
    b.emit("s_cbranch_scc0", loop)
    b.emit("global_store_dword", "v[0:1]", acc, "off")
    b.emit("s_endpgm")
    k = b.finish([], workitem_id=1)
    insts = list(k.insts())
    acc_reg = insts[0].operands[0]
    writes = [i.operands[0] for i in insts if i.mnemonic == "v_mov_b32_e32"][1:]
    assert all(w != acc_reg for w in writes) and writes[0] == writes[1]
    big = Builder("k")
    for _ in range(300):
        big.emit("v_mov_b32_e32", big.v(), 0)
    regs = [i.operands[0] for i in big.blocks[0].insts]
    for r in regs:
        big.emit("v_add_u32_e32", r, r, r)
    big.emit("s_endpgm")
    with pytest.raises(GenError, match="out of v registers"):
        big.finish([])


def test_fix_waits_and_fix_hazards_are_minimal():
    body = """
        s_load_dwordx4 s[4:7], s[0:1], 0x0
        v_mov_b32_e32 v1, 0
        v_lshl_add_u64 v[2:3], s[4:5], 0, v[0:1]
        v_lshl_add_u64 v[4:5], s[6:7], 0, v[0:1]
        global_load_dword v6, v[2:3], off
        global_load_dword v7, v[4:5], off
        v_mov_b32_e32 v8, v6
        v_exp_f32_e32 v9, v7
        v_add_f32_e32 v9, v9, v8
        v_cmp_gt_f32_e64 s[8:9], v9, v8
        v_cndmask_b32_e64 v9, v9, v8, s[8:9]
        global_store_dword v[4:5], v9, off
        s_endpgm
    """
    k = abi.make_kernel("k", mir.parse_body(body, "k"), [abi.Arg("global_buffer"), abi.Arg("global_buffer")])
    assert len(waitcnt.check(k)) >= 3 and len(hazards.check(k)) == 2
    stats = passes.legalize(k)
    assert stats == {"waits_added": 3, "wait_states_added": 3} and not waitcnt.check(k) and not hazards.check(k)
    text = mir.print_kernel_body(k)
    # the older load is waited for alone (vmcnt(1)), the newer only when it is needed
    assert "s_waitcnt lgkmcnt(0)\n\tv_lshl_add_u64 v[2:3]" in text
    assert "s_waitcnt vmcnt(1)\n\tv_mov_b32_e32 v8, v6\n\ts_waitcnt vmcnt(0)\n\tv_exp_f32_e32 v9, v7\n\ts_nop 0" in text
    assert "v_cmp_gt_f32_e64 s[8:9], v9, v8\n\ts_nop 1\n\tv_cndmask" in text
    assert passes.legalize(k) == {"waits_added": 0, "wait_states_added": 0}          # idempotent


# ---- generators ----------------------------------------------------------------------------
@needs_toolchain
@pytest.mark.parametrize("name", PROGRAMS)
def test_every_variant_is_statically_clean(name):
    m = corpus.load(name)
    template = gen.applicable(m)[0]
    assert template == ("rowwise" if "rowwise" in m.tags else "gemm_mfma" if "mfma" in m.tags else "elementwise")
    if template == "gemm_mfma":
        return                                               # covered in test_gemm.py
    sizes = []
    for value in next(iter(gen.TEMPLATES[template]["params"].values())):
        key = next(iter(gen.TEMPLATES[template]["params"]))
        c = gen.generate(m, template, {key: value})
        r = check.static_check(c.module, strict=True)        # generated code may not read undefined registers
        assert r["ok"] and not r["findings"], r["findings"][:3]
        k = c.module.kernel()
        assert k.name == m.entry and c.launch["block"] == [64 if template == "rowwise" else 256]
        text = mir.print_kernel_body(k)
        if template == "rowwise":
            assert "_dpp" in text and "v_readlane_b32" in text and "s_barrier" not in text and "ds_" not in text
            assert k.descriptor["group_segment_fixed_size"] == 0
        elif value > 1:
            assert f"global_load_dwordx{value}" in text
        sizes.append(sum(1 for _ in k.insts()))
    assert sizes == sorted(sizes)                                            # more unrolling, more code
    with pytest.raises(GenError):
        gen.generate(m, "rowwise" if template == "elementwise" else "elementwise")
    with pytest.raises(GenError, match="must be one of"):
        gen.generate(m, template, {key: 3})


def test_recorded_results():
    """`scripts/generated.py`: every variant verified on the full battery and paired with amdclang."""
    rec = json.loads((corpus.BASELINES.with_name("generated-gfx950.json")).read_text())
    assert set(rec["kernels"]) == set(PROGRAMS) and rec["protocol"] == PROTOCOL_VERSION
    for name, k in rec["kernels"].items():
        assert all(v["static"] and v["battery"] != "FAILED" and "/" in v["battery"] for v in k["variants"]), name
        assert k["best"]["outcome"] == "win" and k["best"]["ci95"][0] > 1.01, name
    assert rec["geomean_best"] > 1.2 and rec["geomean_default"] > 1.2


@pytest.mark.parametrize("name", [pytest.param(n, marks=gpu) for n in PROGRAMS])
def test_generated_kernels_pass_the_battery(name, agc_root):
    from agc.runtime import harness
    m = corpus.load(name)
    c = gen.generate(m)
    r = check.static_check(c.module)
    ck = harness.check(m, r["built"].hsaco, launch=c.launch)
    assert ck["ok"] and ck["cases_run"] == ck["cases_total"], ck.get("failures") or ck.get("error")


@pytest.mark.parametrize("name, at_least", [pytest.param("gelu", 1.3, marks=gpu), pytest.param("rmsnorm", 1.2, marks=gpu)])
def test_session_generate_and_win(name, at_least, tmp_path):
    from agc.session import Session, SessionError
    s = Session.open(KERNELS / f"{name}.json", tmp_path)
    prog = s.program()
    assert prog["program"].startswith(f"tair {name}(") and len(prog["templates"]) == 1
    g = s.generate()
    assert g["parent"] is None and g["action"]["name"] == "generate" and g["launch"]["block"] in ([64], [256])
    b = s.bench(g["id"])                                    # static check and battery run first
    assert b["outcome"] == "win" and b["speedup_ci95"][0] > at_least and b["against"] == s.ref_id, b
    assert s.best()["id"] == g["id"]
    # a state derived from a generated one keeps its launch geometry
    e = s.edit(g["id"], [{"op": "insert", "block": s.module(g["id"]).kernel().blocks[-1].label, "index": 0, "text": "s_nop 0"}])
    assert s.launch_of(e["id"]) == g["launch"] and s.check(e["id"])["ok"]
    with pytest.raises(SessionError, match="must be one of"):
        s.generate(params={next(iter(next(iter(prog["templates"].values()))["params"])): 7})


@pytest.mark.parametrize("_", [pytest.param(0, marks=gpu)])
def test_manifest_with_no_kernel_source(_, tmp_path):
    """A tensor program and a manifest go in, a verified binary comes out; there is no HIP at all."""
    from agc.session import Session
    m = Manifest.load(TENSOR)
    assert m.source is None and m.program is not None
    s = Session.open(TENSOR, tmp_path)
    assert s.ref_id is None and s.info()["hip_source"] is False
    g = s.generate("rowwise", {"unroll": 2})
    c = s.check(g["id"])
    assert c["ok"] and c["cases_run"] == c["cases_total"] > 50
    b = s.bench(g["id"])
    assert b["ok"] and b["outcome"] == "no_baseline" and 0.05 < b["candidate_ms"] < 5


def test_a_constant_dominates_every_path():
    """The bug the battery's shape variants found: a constant materialized after the entry block's
    branch was missing on the path that skips the wide loads. It is now placed at the entry, and
    generated code that reads an undefined register is refused."""
    m = corpus.load("cast_bf16")
    k = gen.generate(m, "elementwise", {"elements_per_lane": 4}).module.kernel()
    first = next(k.insts())
    assert first.mnemonic == "s_mov_b32" and str(first.operands[1]) == "0x7fff"
    b = Builder("k")
    r = b.v()
    b.emit("s_cmp_eq_u32", "s2", 0)
    b.emit("s_cbranch_scc1", ".Luse")
    b.emit("v_mov_b32_e32", r, 0)
    b.label(".Luse")
    b.emit("global_store_dword", "v[0:1]", r, "off")
    b.emit("s_endpgm")
    with pytest.raises(GenError, match="reads v2 before it is written on some path"):
        b.finish([], workitem_id=1)
