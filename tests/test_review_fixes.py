"""Regression tests for the Codex review findings on the stacked PRs (issue #27). One test per finding."""
import copy
import json
import os
import threading

import numpy as np
import pytest

from agc import corpus, gen, mir, tair
from agc.manifest import Manifest
from agc.mir import abi, check, emit, loops, waitcnt
from agc.mir.analysis import classify
from conftest import KERNELS, needs_toolchain


def kernel(body, args=(), **kw):
    return abi.make_kernel("k", mir.parse_body(body, "k"), list(args), **kw)


# ---- #16: concurrent builds, timing ------------------------------------------------------------------
@needs_toolchain
def test_concurrent_hip_builds_do_not_share_temporaries(tmp_path, monkeypatch):
    from agc.runtime import toolchain
    monkeypatch.setenv("AGC_CACHE", str(tmp_path))
    src = tmp_path / "k.hip"
    src.write_text('#include <hip/hip_runtime.h>\nextern "C" __global__ void k(float* y) { y[threadIdx.x] = 1.0f; }\n')
    results, errors = [], []

    def build():
        try:
            results.append(toolchain.hip_build(src))
        except Exception as e:                       # noqa: BLE001
            errors.append(e)
    threads = [threading.Thread(target=build) for _ in range(6)]
    [t.start() for t in threads]
    [t.join() for t in threads]
    assert not errors and len({r.hsaco for r in results}) == 1 and len({r.asm for r in results}) == 1
    d = tmp_path / "build" / results[0].key
    assert sorted(p.name for p in d.iterdir()) == ["in.hip", "out.hsaco", "out.s"]  # no temporaries left behind


def test_launch_is_prepared_outside_the_timed_interval():
    """The timer builds the launch before recording the start event (protocol agc-timing-amd-2)."""
    import inspect
    from agc.runtime import timing, worker
    src = inspect.getsource(worker._Timer.time)
    assert src.index("bound.prepared(k)") < src.index("self.start.record") < src.index("submit()") < src.index("self.stop.record")
    assert "pack_args" not in src and timing.PROTOCOL_VERSION == "agc-timing-amd-2"
    with pytest.raises(ValueError, match="unsupported timing protocol"):
        timing.TimingProtocol.from_dict({"version": "agc-timing-amd-1"})


# ---- #17: provenance per kernel ----------------------------------------------------------------------
def test_baselines_carry_provenance_per_kernel():
    base = json.loads(corpus.BASELINES.read_text())
    assert all({"protocol", "toolchain", "recorded"} <= set(k) for k in base["kernels"].values())


# ---- #18: cross-check padding, entry label -----------------------------------------------------------
@needs_toolchain
def test_explicit_nops_at_an_aligned_block_are_not_padding():
    body = "v_mov_b32_e32 v1, 0\n.p2align 2\n.Lnext:\ns_nop 0\ns_nop 0\ns_endpgm\n"
    k = kernel(body)
    built = emit.build(abi.make_module([k]))                 # the cross-check runs inside
    assert emit.crosscheck(abi.make_module([k]), built.hsaco) == []
    padded = kernel("v_mov_b32_e32 v1, 0\ns_nop 0\ns_nop 0\n.p2align 5\n.Lnext:\ns_nop 0\ns_endpgm\n")
    assert emit.crosscheck(abi.make_module([padded]), emit.build(abi.make_module([padded])).hsaco) == []


def test_entry_block_label_survives_printing():
    blocks = mir.parse_body("s_branch .Lentry\n", entry=".Lentry")
    blocks += mir.parse_body("s_endpgm\n", entry=".Ldone")
    k = abi.make_kernel("k", blocks, [])
    text = mir.print_kernel_body(k)
    assert text.splitlines()[0] == ".Lentry:" and ".Ldone:" in text
    named = abi.make_kernel("k", mir.parse_body("s_endpgm\n", entry="k"), [])
    assert mir.print_kernel_body(named) == "\ts_endpgm"      # the kernel's own name is printed by the module


# ---- #19: waitcnt gaps -------------------------------------------------------------------------------
def test_memtime_is_a_pending_scalar_result():
    assert classify(mir.parse_inst("s_memtime s[4:5]")).load
    f = waitcnt.check(kernel("s_memtime s[4:5]\ns_add_u32 s6, s4, 1\ns_endpgm\n"))
    assert [(x["counter"], x["needs"]) for x in f] == [("lgkmcnt", 0)]
    assert waitcnt.check(kernel("s_memtime s[4:5]\ns_waitcnt lgkmcnt(0)\ns_add_u32 s6, s4, 1\ns_endpgm\n")) == []


def test_ds_write_races_with_a_direct_to_lds_load():
    pre = "v_mov_b32_e32 v1, 0\nv_mov_b32_e32 v2, 0\nv_mov_b32_e32 v3, 0\ns_mov_b32 m0, 0\ns_nop 0\nglobal_load_lds_dwordx4 v[2:3], off\n"
    f = waitcnt.check(kernel(pre + "ds_write_b32 v1, v0\ns_waitcnt vmcnt(0) lgkmcnt(0)\ns_endpgm\n", lds_bytes=64))
    assert len(f) == 1 and f[0]["counter"] == "vmcnt" and "LDS contents" in f[0]["message"]
    assert waitcnt.check(kernel(pre + "s_waitcnt vmcnt(0)\nds_write_b32 v1, v0\ns_waitcnt lgkmcnt(0)\ns_endpgm\n", lds_bytes=64)) == []


# ---- #21: session identity, edit order ---------------------------------------------------------------
@needs_toolchain
def test_session_identity_follows_the_source_and_oracle_contents(tmp_path):
    from agc.session import Session
    d = json.loads((KERNELS / "axpy.json").read_text())
    for name in ("axpy.hip", "axpy.tair", "refs.py"):
        (tmp_path / name).write_text((KERNELS / name).read_text())
    (tmp_path / "axpy.json").write_text(json.dumps(d))
    first = Session.open(tmp_path / "axpy.json", tmp_path / "root", quick=True)
    assert Session.open(tmp_path / "axpy.json", tmp_path / "root", quick=True).id == first.id
    for name, edit in (("axpy.hip", "\n// a comment changes the build\n"), ("refs.py", "\n# a different oracle\n"), ("axpy.tair", "\n# a different program\n")):
        before = Session.open(tmp_path / "axpy.json", tmp_path / "root", quick=True).id
        with open(tmp_path / name, "a") as f:
            f.write(edit)
        assert Session.open(tmp_path / "axpy.json", tmp_path / "root", quick=True).id != before, name


@needs_toolchain
def test_insert_and_replace_at_one_address(tmp_path):
    from agc.session import Session
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    e = s.edit("ref", [{"op": "insert", "block": ".LBB0_2", "index": 0, "text": "s_nop 3"},
                       {"op": "replace", "block": ".Lft0", "index": 9, "text": "v_fmac_f32_e32 v5, s4, v4\ns_nop 0", "expect": "v_fmac_f32_e32 v5, s4, v4"},
                       {"op": "insert", "block": ".Lft0", "index": 9, "text": "s_nop 1"}])
    k = s.module(e["id"]).kernel()
    assert [str(i) for i in k.block(".Lft0").insts[9:12]] == ["s_nop 1", "v_fmac_f32_e32 v5, s4, v4", "s_nop 0"]
    assert [str(i) for i in k.block(".LBB0_2").insts] == ["s_nop 3", "s_endpgm"]
    d = s.edit("ref", [{"op": "insert", "block": ".Lft0", "index": 8, "text": "s_nop 2"},
                       {"op": "delete", "block": ".Lft0", "index": 8, "expect": "s_waitcnt vmcnt(0)"}])
    assert [str(i) for i in s.module(d["id"]).kernel().block(".Lft0").insts[8:10]] == ["s_nop 2", "v_fmac_f32_e32 v5, s4, v4"]


# ---- #22: generators ---------------------------------------------------------------------------------
@needs_toolchain
def test_rowwise_in_place_advances_each_address_once():
    d = json.loads((KERNELS / "softmax.json").read_text())
    d["params"] = [{"name": "x", "kind": "tensor", "dtype": "f32", "shape": ["rows", "cols"], "role": "inout"}] + d["params"][2:]
    d["reference"] = {"kind": "tair", "file": "softmax.tair"}
    d["tolerance"] = {"x": {"rtol": 1e-3, "atol": 1e-6}}
    m = Manifest.from_dict(d, KERNELS / "softmax.json")
    k = gen.generate(m, "rowwise", {"unroll": 2}).module.kernel()
    assert check.static_check(abi.make_module([k]), strict=True, encode=False)["ok"]
    # in the output pass every loop body advances its one address once (not once per role)
    for b in k.blocks:
        stores = [i for i in b.insts if i.mnemonic.startswith("global_store")]
        if stores:
            addr = stores[0].operands[0]
            advances = [i for i in b.insts if i.mnemonic == "v_lshl_add_u64" and i.operands[0] == addr and i.operands[1] == addr]
            assert len(advances) <= 1, mir.print_kernel_body(k)


def test_cast_f32_of_bf16_restores_the_float():
    from agc.gen.builder import Builder
    from agc.gen.expr import ExprCompiler
    p = tair.parse("tair f(x: f32[N]) -> (y: f32[N]) {\n  y = cast_f32(cast_bf16(x))\n}")
    b = Builder("k")
    r = ExprCompiler(b).compile(p.body[0].expr, {"x": b.V(1)}, {})
    ops = [i.mnemonic for i in b.blocks[0].insts]
    assert ops[-2:] == ["v_lshrrev_b32_e32", "v_lshlrev_b32_e32"] and str(b.blocks[0].insts[-1].operands[1]) == "16"
    x = np.array([1.0, -2.5, 3.14159], np.float32)
    assert np.allclose(tair.evaluate(p, {"x": x})["y"].astype(np.float32), x, rtol=1e-2)


def test_tair_reference_uses_manifest_output_names():
    from agc.runtime import reference
    d = json.loads((KERNELS / "axpy.json").read_text())
    d["reference"] = {"kind": "tair", "file": "axpy.tair"}              # the program calls its output y_out
    m = Manifest.from_dict(d, KERNELS / "axpy.json")
    r = m.resolve({"N": 8})
    x, y = np.arange(8, dtype=np.float32), np.ones(8, np.float32)
    out = reference.evaluate(m, {"x": x, "y": y}, r)
    assert set(out) == {"y"} and np.allclose(out["y"], 1.5 * x + y)


# ---- #24: GEMM -----------------------------------------------------------------------------------------
def test_gemm_rejects_k_that_depends_on_a_dynamic_symbol():
    d = json.loads((KERNELS / "gemm_bf16.json").read_text())
    d["shapes"] = {"M": 200, "N": 136, "D": 240}
    d["bench_shapes"] = {"M": 2048, "N": 2048, "D": 2032}
    d["dynamic"] = ["M", "N", "D"]
    for p in d["params"]:
        if p.get("shape"):
            p["shape"] = ["D + 16" if e == "K" else e for e in p["shape"]]
        if p.get("value") == "K":
            p["value"] = "D + 16"
    m = Manifest.from_dict(d, KERNELS / "gemm_bf16.json")
    with pytest.raises(gen.GenError, match="depends on the dynamic symbol"):
        gen.generate(m, "gemm_mfma")


# ---- #25: unroll_loads -----------------------------------------------------------------------------------
LOOP = """
    s_load_dwordx4 s[4:7], s[0:1], 0x0
    s_mov_b32 s9, 64
    v_mov_b32_e32 v1, 0
    v_mov_b32_e32 v8, 0
    v_mov_b32_e32 v9, 0
    s_waitcnt lgkmcnt(0)
    v_lshl_add_u64 v[2:3], s[4:5], 0, v[0:1]
.Lloop:
{body}
    s_add_i32 s9, s9, -1
    v_lshl_add_u64 v[2:3], v[2:3], 0, {step}
    s_cmp_eq_u32 s9, 0
    s_waitcnt vmcnt(0)
{arith}
    s_cbranch_scc0 .Lloop
.Lexit:
    global_store_dword v[2:3], v8, off
    s_endpgm
"""


def loop_kernel(body, arith, step=8):
    return kernel(LOOP.format(body=body, arith=arith, step=step), [abi.Arg("global_buffer"), abi.Arg("global_buffer")])


def test_unroll_renames_elements_of_a_loaded_tuple():
    k = loop_kernel("    global_load_dwordx2 v[4:5], v[2:3], off", "    v_add_f32_e32 v8, v8, v4\n    v_add_f32_e32 v8, v8, v5")
    loops.unroll_loads(k, 4, wide=False)
    body = [str(i) for i in k.block(".Lunroll0").insts]
    loaded = [x.split()[1].rstrip(",") for x in body if x.startswith("global_load_dwordx2")]
    assert len(loaded) == 4 and "v[4:5]" not in loaded
    adds = [x for x in body if x.startswith("v_add_f32_e32 v8, v8,")]
    assert len(adds) == 8 and not any(x.endswith(" v4") or x.endswith(" v5") for x in adds)
    want = [f"v{int(t[2:].split(':')[0]) + e}" for t in loaded for e in (0, 1)]
    assert [x.split()[-1] for x in adds] == want                              # each element of each copy, in order
    assert check.static_check(abi.make_module([k]), encode=False)["ok"]


def test_unroll_refuses_two_loads_into_one_register():
    k = loop_kernel("    global_load_dword v4, v[2:3], off\n    global_load_dword v4, v[2:3], off offset:4",
                    "    v_add_f32_e32 v8, v8, v4")
    with pytest.raises(loops.NotApplicable, match="another load of the loop already wrote"):
        loops.unroll_loads(k, 4, loop=".Lloop")


def test_unroll_refuses_arithmetic_that_reads_the_counter_or_a_pointer():
    k = loop_kernel("    global_load_dword v4, v[2:3], off", "    v_add_u32_e32 v8, s9, v4")
    with pytest.raises(loops.NotApplicable, match="reads the counter or a pointer"):
        loops.unroll_loads(k, 4, loop=".Lloop")
    k = loop_kernel("    global_load_dword v4, v[2:3], off", "    v_add_u32_e32 v8, v2, v4")
    with pytest.raises(loops.NotApplicable, match="reads the counter or a pointer"):
        loops.unroll_loads(k, 4, loop=".Lloop")


def test_unroll_refuses_a_timestamp_read_instead_of_crashing():
    for op in ("s_memtime", "s_memrealtime"):
        k = loop_kernel(f"    global_load_dword v4, v[2:3], off\n    {op} s[10:11]", "    v_add_f32_e32 v8, v8, v4")
        with pytest.raises(loops.NotApplicable, match="without an address"):
            loops.unroll_loads(k, 4, loop=".Lloop")
        assert loops.find_loops(k) == []                                     # the policy skips it, no exception


# ---- checker findings on amdclang's builds of the LLM benchmark (#29) -----------------------------------
def test_amdclang_forms_from_the_llm_benchmark_are_legal():
    from agc.arch.model import load as load_arch
    from agc.isa import table
    from agc.mir.asm import parse_inst
    from agc.mir.verify import check_inst
    isa, arch = table(), load_arch()
    for text in ("v_readfirstlane_b32 s5, v1", "s_set_gpr_idx_on s16, gpr_idx(DST)", "s_set_gpr_idx_on s17, gpr_idx(SRC0)"):
        assert check_inst(parse_inst(text), isa, arch) is None, text
    assert check_inst(parse_inst("v_add_f32 v1, v2, v3"), isa, arch)          # other two-form names still need a suffix
    assert check_inst(parse_inst("s_set_gpr_idx_on s16, vmcnt(0)"), isa, arch)


def test_packed_operand_halves_follow_op_sel():
    from agc.mir.analysis import classify
    from agc.mir.asm import parse_inst
    u = classify(parse_inst("v_pk_fma_f32 v[6:7], s[10:11], v[10:11], v[8:9] op_sel_hi:[0,1,1]")).uses
    assert ("s", 10) in u and ("s", 11) not in u and {("v", 10), ("v", 11), ("v", 8), ("v", 9)} <= u
    u = classify(parse_inst("v_pk_add_f32 v[30:31], v[34:35], s[38:39] op_sel_hi:[1,0]")).uses
    assert ("s", 38) in u and ("s", 39) not in u and ("v", 35) in u
    u = classify(parse_inst("v_pk_add_f32 v[30:31], v[34:35], s[38:39] op_sel:[0,1] op_sel_hi:[1,1]")).uses
    assert ("s", 39) in u and ("s", 38) not in u
    assert {("v", 2), ("v", 3)} <= classify(parse_inst("v_pk_mul_f32 v[0:1], v[2:3], v[4:5]")).uses


def test_transforms_refuse_indexed_vector_registers():
    import pytest
    from agc.mir.asm import parse_inst
    from agc.mir.ir import Block, Kernel
    from agc.mir.loops import NotApplicable, refuse_indexed
    k = Kernel("k", [Block("k", [parse_inst("s_set_gpr_idx_on s16, gpr_idx(DST)"), parse_inst("s_set_gpr_idx_off"), parse_inst("s_endpgm")])], {}, {})
    with pytest.raises(NotApplicable, match="indexed"):
        refuse_indexed(k)
