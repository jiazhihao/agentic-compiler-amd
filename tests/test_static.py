"""M4: static safety. CFG and def/use from the ISA table, the waitcnt checker, the hazard checker,
the kernel contract; zero findings on amdclang's output and a seeded mutation suite."""
import collections
from pathlib import Path

import pytest

from agc import corpus, mir
from agc.arch.model import load as load_arch
from agc.mir import abi, check, hazards, mutate, verify, waitcnt
from agc.mir.analysis import cfg, classify, entry_defined, liveness, undefined_reads
from agc.runtime import harness, toolchain
from conftest import needs_toolchain

FIXTURES = Path(__file__).parent / "fixtures"
PTRS = [abi.Arg("global_buffer"), abi.Arg("global_buffer")]


def kernel(body: str, args=PTRS, **kw):
    return abi.make_kernel("k", mir.parse_body(body, "k"), args, **kw)


def kinds(findings, errors_only=True):
    return [(f["kind"], f.get("rule") or f.get("counter") or f.get("register"))
            for f in findings if not errors_only or f.get("severity") != "warning"]


# ---- analysis ------------------------------------------------------------------------------
def test_classify_defs_and_uses():
    c = lambda text: classify(mir.parse_inst(text))
    i = c("v_fmac_f32_e32 v5, s4, v4")
    assert i.valu and i.defs == {("v", 5)} and i.uses == {("v", 5), ("s", 4), ("v", 4), ("exec", 0)}   # the accumulator is read
    i = c("s_and_saveexec_b64 s[2:3], vcc")
    assert i.salu and i.defs == {("s", 2), ("s", 3), ("exec", 0), ("scc", 0)} and i.uses == {("vcc", 0), ("exec", 0)}
    i = c("v_cmp_gt_i32_e32 vcc, s5, v0")
    assert i.defs == {("vcc", 0)} and ("s", 5) in i.uses
    i = c("global_load_dword v4, v[2:3], off")
    assert i.vmem and i.load and not i.store and i.defs == {("v", 4)} and {("v", 2), ("v", 3)} <= i.uses
    i = c("global_store_dword v[0:1], v5, off")
    assert i.vmem and i.store and not i.defs
    i = c("ds_read_b32 v1, v0 offset:4")
    assert i.ds and not i.vmem and i.load and ("lds", 0) in i.uses
    i = c("s_load_dwordx2 s[4:5], s[0:1], 0x10")
    assert i.smem and i.load and i.defs == {("s", 4), ("s", 5)}
    i = c("global_load_lds_dwordx4 v[2:3], off")
    assert i.lds_dma and i.defs == {("lds", 0)} and ("m0", 0) in i.uses
    i = c("v_mfma_f32_32x32x16_bf16 a[0:15], v[0:3], v[4:7], a[0:15]")
    assert i.mfma and i.valu and len(i.defs) == 16 and [f for f, _ in i.explicit_uses] == ["SRC0", "SRC1", "SRC2"]
    assert c("s_nop 3").wait_states == 4 and c("v_exp_f32_e32 v0, v1").trans and c("s_cbranch_scc1 .L").cond_branch
    assert c("s_cbranch_execz .L").uses == {("exec", 0)} and c("s_endpgm").terminator


def test_cfg_splits_at_branches_and_liveness():
    k = kernel("""
        s_cmp_lt_i32 s2, 1
        s_cbranch_scc1 .Lskip
        v_mov_b32_e32 v1, 0
        s_branch .Lend
    .Lskip:
        v_mov_b32_e32 v1, 1
    .Lend:
        v_add_u32_e32 v2, v1, v0
        s_endpgm
    """)
    assert [b.label for b in k.blocks] == ["k", ".Lft0", ".Lskip", ".Lend"]
    g = cfg(k)
    assert g.succ == [[2, 1], [3], [3], []] and g.pred[3] == [1, 2]
    live = liveness(g, masked_defs_kill=True)
    assert ("v", 1) in live[1][0] and ("v", 1) not in live[0][0] and ("v", 0) in live[0][0]
    assert ("v", 1) in liveness(g)[0][0]                    # a masked write does not end liveness by default
    assert live[3][-1] == frozenset() and undefined_reads(g) == []
    assert entry_defined(k) >= {("s", 0), ("s", 1), ("s", 2), ("v", 0), ("exec", 0)} and ("s", 3) not in entry_defined(k)


def test_undefined_reads_warning_and_error():
    k = kernel("""
        s_cmp_lt_i32 s2, 1
        s_cbranch_scc1 .Lend
        v_mov_b32_e32 v1, 0
    .Lend:
        v_add_u32_e32 v2, v1, v9
        s_endpgm
    """)
    f = [x for x in check.check_kernel(k) if x["kind"] == "undefined_read"]
    assert {(x["register"], x["severity"]) for x in f} == {("v1", "warning"), ("v9", "error")}
    assert not check.static_check(abi.make_module([k]), encode=False)["ok"]


# ---- waitcnt -------------------------------------------------------------------------------
LOADS = """
    s_load_dwordx4 s[4:7], s[0:1], 0x0
    s_waitcnt lgkmcnt(0)
    v_mov_b32_e32 v1, 0
    v_lshl_add_u64 v[2:3], s[4:5], 0, v[0:1]
    v_lshl_add_u64 v[0:1], s[6:7], 0, v[0:1]
    global_load_dword v4, v[2:3], off
    global_load_dword v5, v[0:1], off
"""


@pytest.mark.parametrize("tail, expect", [
    ("s_waitcnt vmcnt(0)\nv_add_f32_e32 v6, v4, v5\ns_endpgm", []),
    ("s_waitcnt vmcnt(1)\nv_mov_b32_e32 v6, v4\ns_waitcnt vmcnt(0)\nv_add_f32_e32 v6, v6, v5\ns_endpgm", []),   # in order
    ("v_add_f32_e32 v6, v4, v5\ns_endpgm", [("waitcnt", "vmcnt"), ("waitcnt", "vmcnt")]),
    ("s_waitcnt vmcnt(1)\nv_add_f32_e32 v6, v4, v5\ns_endpgm", [("waitcnt", "vmcnt")]),                        # v5 still pending
    ("s_waitcnt lgkmcnt(0)\nv_add_f32_e32 v6, v4, v5\ns_endpgm", [("waitcnt", "vmcnt"), ("waitcnt", "vmcnt")]),  # the wrong counter
    ("v_mov_b32_e32 v4, 0\ns_waitcnt vmcnt(0)\ns_endpgm", [("waitcnt", "vmcnt")]),                             # overwrite before arrival
    ("global_store_dword v[2:3], v1, off\ns_waitcnt vmcnt(1)\nv_add_f32_e32 v6, v4, v5\ns_endpgm", []),         # a store counts as an event
    ("global_store_dword v[2:3], v1, off\ns_waitcnt vmcnt(2)\nv_mov_b32_e32 v6, v4\ns_endpgm", []),
    ("global_store_dword v[2:3], v1, off\ns_waitcnt vmcnt(2)\nv_mov_b32_e32 v6, v5\ns_endpgm", [("waitcnt", "vmcnt")]),
    ("s_barrier\ns_waitcnt vmcnt(0)\ns_endpgm", [("waitcnt", "vmcnt")]),
    ("s_waitcnt vmcnt(0)\ns_barrier\ns_endpgm", []),
])
def test_waitcnt_vector_memory(tail, expect):
    assert kinds(waitcnt.check(kernel(LOADS + tail))) == expect


def test_waitcnt_reports_the_wait_needed():
    f = waitcnt.check(kernel(LOADS + "global_store_dword v[2:3], v1, off\nv_mov_b32_e32 v6, v4\ns_endpgm"))
    assert f[0]["needs"] == 2 and "s_waitcnt vmcnt(2)" in f[0]["message"] and f[0]["inst"] == "v_mov_b32_e32 v6, v4"


def test_waitcnt_scalar_loads_are_out_of_order():
    body = """
        s_load_dwordx2 s[4:5], s[0:1], 0x0
        s_load_dword s6, s[0:1], 0x10
        s_waitcnt lgkmcnt(1)
        s_add_u32 s7, s4, 1
        s_waitcnt lgkmcnt(0)
        s_add_u32 s7, s6, 1
        s_endpgm
    """
    f = waitcnt.check(kernel(body))
    assert kinds(f) == [("waitcnt", "lgkmcnt")] and f[0]["needs"] == 0 and "s4" in f[0]["message"]
    lds = """
        v_mov_b32_e32 v1, 0
        ds_write_b32 v1, v0
        ds_read_b32 v2, v1
        ds_read_b32 v3, v1 offset:4
        s_waitcnt lgkmcnt(1)
        v_mov_b32_e32 v4, v2
        s_waitcnt lgkmcnt(0)
        v_mov_b32_e32 v4, v3
        s_endpgm
    """
    assert waitcnt.check(kernel(lds, lds_bytes=64)) == []           # LDS returns in order
    dma = "global_load_lds_dwordx4 v[2:3], off\nv_mov_b32_e32 v1, 0\nds_read_b32 v4, v1\ns_waitcnt lgkmcnt(0)\ns_endpgm"
    f = waitcnt.check(kernel("v_mov_b32_e32 v2, 0\nv_mov_b32_e32 v3, 0\ns_mov_b32 m0, 0\ns_nop 0\n" + dma, lds_bytes=64))
    assert kinds(f) == [("waitcnt", "vmcnt")] and "LDS contents" in f[0]["message"]


def test_waitcnt_across_a_join():
    """The wait must hold on every path (the bug the mutation suite found in an early CFG)."""
    body = """
        s_load_dwordx2 s[4:5], s[0:1], 0x0
        s_cmp_lt_i32 s2, 1
        s_cbranch_scc1 .Lskip
        s_waitcnt lgkmcnt(0)
        s_add_u32 s6, s4, 1
    .Lskip:
        {wait}
        s_add_u32 s7, s5, 1
        s_endpgm
    """
    assert waitcnt.check(kernel(body.format(wait="s_waitcnt lgkmcnt(0)"))) == []
    f = waitcnt.check(kernel(body.format(wait="")))
    assert kinds(f) == [("waitcnt", "lgkmcnt")] and f[0]["block"] == ".Lskip"


# ---- hazards -------------------------------------------------------------------------------
@pytest.mark.parametrize("body, rule, needs", [
    ("v_cmp_gt_i32_e64 s[4:5], v0, v1\nv_cndmask_b32_e64 v2, v0, v1, s[4:5]", "valu_reads_sgpr_after_valu_write", 2),
    ("v_cmp_gt_i32_e64 s[4:5], v0, v1\ns_nop 0\nv_cndmask_b32_e64 v2, v0, v1, s[4:5]", "valu_reads_sgpr_after_valu_write", 1),
    ("v_cmp_gt_i32_e64 s[4:5], v0, v1\ns_nop 1\nv_cndmask_b32_e64 v2, v0, v1, s[4:5]", None, 0),
    ("v_cmp_gt_i32_e32 vcc, v0, v1\nv_cndmask_b32_e32 v2, v0, v1, vcc", "valu_reads_sgpr_after_valu_write", 2),
    ("v_exp_f32_e32 v1, v0\nv_add_f32_e32 v2, v1, v0", "valu_reads_trans_result", 1),
    ("v_exp_f32_e32 v1, v0\nv_mov_b32_e32 v3, 0\nv_add_f32_e32 v2, v1, v0", None, 0),
    ("v_exp_f32_e32 v1, v0\nv_sqrt_f32_e32 v2, v1", None, 0),                                   # trans to trans
    ("v_readfirstlane_b32_e32 s4, v0\nglobal_load_dword v1, v0, s[4:5]", "vmem_reads_sgpr_after_valu_write", 5),
    ("v_readfirstlane_b32_e32 s4, v0\ns_nop 3\nglobal_load_dword v1, v0, s[4:5]", "vmem_reads_sgpr_after_valu_write", 1),
    ("v_mov_b32_e32 v1, 0\nv_add_u32_dpp v2, v1, v0 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf", "dpp_reads_vgpr_after_write", 2),
    ("v_cmp_gt_i32_e32 vcc, v0, v1\nv_div_fmas_f32 v2, v0, v1, v0", "div_fmas_after_valu_vcc_write", 4),
    ("v_mov_b32_e32 v8, 0\nv_mfma_f32_16x16x32_bf16 a[0:3], v[8:11], v[4:7], a[0:3]", "mfma_reads_vgpr_after_valu_write", 2),
    # MFMA results: an XDL 8-pass result read by a VALU needs 12 wait states on gfx950, by MFMA A/B 12
    ("v_mfma_f32_32x32x16_bf16 v[16:31], v[0:3], v[4:7], 0\nv_mov_b32_e32 v8, v16", "mfma_result_read", 12),
    ("v_mfma_f32_32x32x16_bf16 v[16:31], v[0:3], v[4:7], 0\ns_nop 10\nv_mov_b32_e32 v8, v16", "mfma_result_read", 1),
    ("v_mfma_f32_32x32x16_bf16 v[16:31], v[0:3], v[4:7], 0\ns_nop 11\nv_mov_b32_e32 v8, v16", None, 0),
    ("v_mfma_f32_32x32x16_bf16 v[16:31], v[0:3], v[4:7], 0\nv_mov_b32_e32 v16, 0", "mfma_result_overwritten", 12),
    ("v_mfma_f32_32x32x16_bf16 v[16:31], v[0:3], v[4:7], 0\nglobal_store_dword v[0:1], v16, off", "mfma_result_read", 12),
    ("v_mfma_f32_16x16x32_bf16 v[8:11], v[0:3], v[4:7], 0\nv_mfma_f32_16x16x32_bf16 a[0:3], v[8:11], v[4:7], a[0:3]", "mfma_result_read_as_ab", 8),
    # the accumulator chain on one MFMA needs nothing; a partial overlap or another MFMA does
    ("v_mfma_f32_32x32x16_bf16 a[0:15], v[0:3], v[4:7], a[0:15]\nv_mfma_f32_32x32x16_bf16 a[0:15], v[0:3], v[4:7], a[0:15]", None, 0),
    ("v_mfma_f32_4x4x4_16b_f16 a[0:3], v[0:1], v[2:3], a[0:3]\nv_mfma_f32_4x4x4_16b_f16 a[0:3], v[0:1], v[2:3], a[0:3]", "mfma_result_read_as_c", 2),
    ("v_mfma_f32_16x16x32_bf16 a[0:3], v[0:3], v[4:7], a[0:3]\nv_mfma_f32_16x16x16_bf16 a[0:3], v[0:1], v[2:3], a[0:3]", "mfma_result_read_as_c", 6),
    ("v_mfma_f32_32x32x16_bf16 a[0:15], v[0:3], v[4:7], a[0:15]\nv_mov_b32_e32 v9, 0\nv_accvgpr_write_b32 a0, v9", "mfma_result_overwritten", 11),
    ("v_mfma_f32_32x32x2_f32 a[0:15], v0, v1, a[0:15]\nv_accvgpr_read_b32 v8, a0", "mfma_result_read", 18),   # SGEMM 16-pass: P + 2
])
def test_hazard_rules(body, rule, needs):
    f = hazards.check(kernel("v_mov_b32_e32 v0, 0\nv_mov_b32_e32 v1, 0\ns_nop 15\n" + body + "\ns_nop 15\ns_nop 15\ns_endpgm"))
    if rule is None:
        assert f == []
    else:                                        # the named rule is the binding one (others may also apply)
        worst = max(f, key=lambda x: x["needs"])
        assert (worst["rule"], worst["needs"]) == (rule, needs), f
        assert f"s_nop {needs - 1}" in worst["message"]


def test_hazard_distance_is_the_minimum_over_paths():
    body = """
        v_cmp_gt_i32_e64 s[4:5], v0, v0
        s_cbranch_scc1 .Luse
        s_nop 3
    .Luse:
        v_cndmask_b32_e64 v2, v0, v0, s[4:5]
        s_endpgm
    """
    f = hazards.check(kernel(body))
    assert [(x["rule"], x["needs"]) for x in f] == [("valu_reads_sgpr_after_valu_write", 1)]   # the branch itself is one wait state
    assert hazards.check(kernel("s_getreg_b32 s4, hwreg(HW_REG_MODE)\ns_endpgm"))[0]["rule"] == "unmodelled"


def test_hazard_data_is_source_tagged():
    arch = load_arch()
    assert all(v.source == "llvm" and isinstance(v.value, int) for v in arch.section("hazards").values())
    R = hazards.Rules(arch)
    c = lambda t: classify(mir.parse_inst(t))
    assert R.mfma(c("v_mfma_f32_32x32x16_bf16 a[0:15], v[0:3], v[4:7], a[0:15]")) == (8, "xdl")
    assert R.mfma(c("v_mfma_f32_16x16x32_bf16 a[0:3], v[0:3], v[4:7], a[0:3]")) == (4, "xdl")
    assert R.mfma(c("v_mfma_f32_32x32x2_f32 a[0:15], v0, v1, a[0:15]")) == (16, "sgemm")
    assert R.mfma(c("v_mfma_f64_16x16x4_f64 a[0:7], v[0:1], v[2:3], a[0:7]")) == (16, "dgemm")


# ---- contract ------------------------------------------------------------------------------
def test_contract():
    k = kernel("v_mov_b32_e32 v7, 0\nv_accvgpr_write_b32 a3, v7\ns_mov_b32 s9, 0\ns_endpgm")
    arch = load_arch()
    assert check.check_contract(k, arch) == []
    assert (k.descriptor["accum_offset"], k.descriptor["next_free_vgpr"], k.metadata[".agpr_count"]) == (8, 12, 4)
    for field, value in (("accum_offset", 4), ("next_free_vgpr", 9), ("next_free_sgpr", 9)):
        bad = kernel("v_mov_b32_e32 v7, 0\nv_accvgpr_write_b32 a3, v7\ns_mov_b32 s9, 0\ns_endpgm")
        bad.descriptor[field] = value
        assert [f["field"] for f in check.check_contract(bad, arch)] == [field]
    bad = kernel("s_endpgm")
    bad.metadata[".sgpr_count"] = 0
    bad.descriptor["kernarg_size"] = 8
    assert len(check.check_contract(bad, arch)) == 3          # sgpr_count, kernarg mismatch, arguments beyond the segment


# ---- amdclang output and mutations ---------------------------------------------------------
@needs_toolchain
@pytest.mark.parametrize("name", corpus.names())
def test_corpus_is_clean_and_mutations_are_caught(name):
    b = harness.reference_build(corpus.load(name))
    m = mir.parse(b.asm)
    r = check.static_check(m)
    assert r["ok"], [f for f in r["findings"] if f.get("severity") != "warning"]
    assert toolchain.section(r["built"].hsaco, ".text") == toolchain.section(b.hsaco, ".text")
    total, missed = collections.Counter(), []
    for cls, desc, mm in mutate.mutations(m):
        legal = cls == "wrong_class" and not verify.verify(mm)      # the operand accepts either register file
        if legal:
            continue                                                # a semantic change: the battery's job
        total[cls] += 1
        if check.static_check(mm, encode=False)["ok"]:
            missed.append((cls, desc))
    assert not missed, missed
    assert total["drop_wait"] >= 2 and total["weaken_wait"] >= 2 and total["understate"] == 4


@needs_toolchain
def test_mfma_hazards_against_amdclang():
    m = mir.parse(toolchain.hip_build(FIXTURES / "mfma_probe.hip").asm)
    assert sum(i.mnemonic.startswith("v_mfma") for k in m.kernels for i in k.insts()) == 9
    findings = [f for k in m.kernels for f in check.check_kernel(k) if f.get("severity") != "warning"]
    # One divergence, kept on purpose: ROCm LLVM (amd-staging) requires wait states when two different
    # MFMAs share an accumulator; the installed amdclang emits none.
    assert [(f["kernel"], f["rule"], f["needs"]) for f in findings] == [("mfma_feed", "mfma_result_read_as_c", 6)]
    nops = 0
    for k in m.kernels:
        one = mir.Module(m.target, m.code_object_version, [k], m.metadata)
        before = len([f for f in check.check_kernel(k) if f.get("severity") != "warning"])
        for cls, desc, mm in mutate.mutations(one):
            if cls == "drop_nop":
                nops += 1
                after = [f for f in check.check_kernel(mm.kernels[0]) if f.get("severity") != "warning"]
                assert len(after) > before, (k.name, desc)
    assert nops >= 15
