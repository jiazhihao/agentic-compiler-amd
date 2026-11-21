"""M3: the machine IR owns the assembly. Parse/print, the ISA verifier (and its agreement with
llvm-mc), exact re-emission of every amdclang build, and a kernel written by hand in mir."""
import os
import subprocess
import tempfile
from pathlib import Path

import pytest

from agc import corpus, mir
from agc.arch.model import load as load_arch
from agc.isa import table
from agc.mir import abi, emit, verify
from agc.mir.ir import Call, Imm, Label, Reg
from agc.runtime import harness, toolchain
from conftest import gpu, needs_toolchain

HAND = Path(__file__).parent / "mir" / "axpy_hand.s"
AXPY_ARGS = [abi.Arg("global_buffer"), abi.Arg("global_buffer"), abi.Arg("by_value", 4), abi.Arg("by_value", 4)]

LEGAL = """
s_load_dwordx4 s[0:3], s[0:1], 0x0
s_load_dword s3, s[0:1], s5
s_waitcnt vmcnt(0) lgkmcnt(0)
s_and_saveexec_b64 s[2:3], vcc
s_mov_b64 s[36:37], 0x400
s_add_u32 s0, s1, 0x12345
v_add_u32_e32 v12, 0x400, v4
v_add_f32_e64 v0, |v1|, -v2
v_cmp_gt_i32_e32 vcc, s5, v0
v_cmp_gt_u32_e64 s[10:11], 16, v0
v_cndmask_b32_e32 v4, v6, v5, vcc
v_cndmask_b32_e64 v4, v3, v10, s[10:11]
v_div_scale_f32 v4, s[22:23], v6, v6, v1
v_mad_u64_u32 v[10:11], s[0:1], v1, s6, v[10:11]
v_lshl_add_u64 v[10:11], v[10:11], 2, s[8:9]
v_fmaak_f32 v5, v4, v5, 0xbd5c1c4e
v_fma_f32 v4, v4, -2.0, 1.0
v_mov_b32_e32 v0, 3.5
v_pk_mul_f32 v[16:17], v[16:17], v[38:39]
v_bitop3_b16 v11, v14, 3, v11 bitop3:0xc8
global_load_dword v14, v[10:11], off
global_load_dword v1, v[2:3], off offset:4095
global_load_dwordx4 a[0:3], v[2:3], off
global_load_dwordx4 v[6:9], v[2:3], off
global_load_dwordx3 v[4:6], v[2:3], off
s_load_dwordx8 s[12:19], s[2:3], 0x0
global_store_dword v0, v1, s[0:1]
global_load_lds_dwordx4 v[2:3], off
ds_read2_b32 v[38:39], v12 offset0:160 offset1:176
ds_read_b128 a[0:3], v1
ds_read_b32 v0, v1 offset:65535
ds_write_b64 v1, v[2:3]
v_mfma_f32_32x32x16_bf16 a[0:15], v[0:3], v[4:7], a[0:15]
v_mfma_f32_16x16x32_bf16 a[0:3], v[0:3], v[4:7], a[0:3]
v_add_u32_dpp v0, v1, v2 quad_perm:[1,0,3,2] row_mask:0xf bank_mask:0xf
v_mov_b32_dpp v0, v1 row_shr:1 row_mask:0xf bank_mask:0xf bound_ctrl:1
v_accvgpr_write_b32 a0, v0
v_readlane_b32 s0, v1, s2
s_nop 0
s_barrier
s_endpgm
""".strip().splitlines()

ILLEGAL = {
    "v_add_u32_e32 v0, v1, s2": "VSRC1",
    "v_add_u32_e64 v0, 0x1234, v1": "no literal",
    "s_mov_b32 v0, s1": "v register is not allowed",
    "v_mov_b32_e32 v[0:1], v2": "32 bits",
    "global_load_dword v1, v2, off": "64 bits",
    "s_load_dwordx2 s4, s[0:1], 0x0": "64 bits",
    "v_fma_f32_e32 v0, v1, v2, v3": "unknown instruction",
    "v_frobnicate v0": "unknown instruction",
    "s_waitcnt vmcnt(64)": "at most 63",
    "v_mov_b32_e32 v300, v0": "out of range",
    "ds_read_b32 v0, s1": "ADDR",
    "v_fmac_f32_e32 v0, 1.5, 2.5": "no literal",
    "s_add_u32 s0, 0x12345, 0x54321": "more than one literal",
    "v_add_f32_e32 v0, |v1|, v2": "neg/abs",
    "v_cmp_gt_i32_e32 s[0:1], v0, v1": "OPR_VCC",
    "v_cndmask_b32_e32 v0, v1, v2, s[0:1]": "OPR_VCC",
    "s_and_saveexec_b64 s2, vcc": "64 bits",
    "v_mfma_f32_32x32x16_bf16 a[0:15], v[0:7], v[8:15], a[0:15]": "128 bits",
    "ds_read_b32 v0, v1 offset:65536": "outside 0..65535",
    "global_load_dword v1, v[2:3], off offset:4096": "outside -4096..4095",
    "v_add_f32_e32 v0, v1, v2 clamp": "clamp",
    "v_add_u32_e32 v0, v1": "takes 3 operands",
    "global_load_dwordx4 v[5:8], v[2:3], off": "multiple of 2",
    "global_load_dword v1, v[3:4], off": "multiple of 2",
    "v_mfma_f32_32x32x16_bf16 a[1:16], v[0:3], v[4:7], a[1:16]": "multiple of 2",
    "s_load_dwordx2 s[13:14], s[6:7], 0x0": "multiple of 2",
    "s_load_dwordx4 s[14:17], s[6:7], 0x0": "multiple of 4",
    "s_mov_b64 s[5:6], 0": "multiple of 2",
}


def test_operands_parse_and_print():
    cases = {"v3": Reg("v", 3), "s[4:5]": Reg("s", 4, 2), "a[0:15]": Reg("a", 0, 16), "vcc": Reg("vcc"),
             "exec": Reg("exec"), "off": Reg("off"), "-|v2|": Reg("v", 2, neg=True, abs=True), "|v2|": Reg("v", 2, abs=True),
             "0x400": Imm("0x400"), "-2.0": Imm("-2.0"), "-1": Imm("-1"), ".LBB0_7": Label(".LBB0_7"),
             "vmcnt(0)": Call("vmcnt", ("0",))}
    for text, want in cases.items():
        got = mir.asm.parse_operand(text)
        assert got == want and str(got) == text
    assert Imm("0x400").value == 1024 and Imm("-2.0").value == -2.0 and Imm("-2.0").is_float
    assert Reg("s", 4, 2).regs() == (("s", 4), ("s", 5)) and Reg("vcc").width == 2
    for bad in ("v[3:1]", "|7|", "q9!", ""):
        with pytest.raises(mir.AsmError):
            mir.asm.parse_operand(bad)


@pytest.mark.parametrize("line", LEGAL)
def test_instructions_round_trip_and_verify(line):
    inst = mir.parse_inst(line)
    assert str(inst) == line
    assert verify.check_inst(inst, table(), load_arch()) is None


@pytest.mark.parametrize("line", ILLEGAL)
def test_verifier_rejects(line):
    why = verify.check_inst(mir.parse_inst(line), table(), load_arch())
    assert why and ILLEGAL[line] in why, why


def _llvm_accepts(line: str) -> bool:
    with tempfile.NamedTemporaryFile("w", suffix=".s", delete=False) as f:
        f.write(f'\t.amdgcn_target "amdgcn-amd-amdhsa--gfx950"\n\t.text\nf:\n\t{line}\n')
    try:
        return subprocess.run([toolchain.tool("llvm-mc"), "-triple=amdgcn-amd-amdhsa", "-mcpu=gfx950",
                               "-filetype=null", f.name], capture_output=True).returncode == 0
    finally:
        os.unlink(f.name)


@needs_toolchain
def test_verifier_agrees_with_the_assembler():
    """Two independent judges: the ISA table (AMD's specification) and llvm-mc."""
    for line in LEGAL:
        assert _llvm_accepts(line), line
    for line in ILLEGAL:
        assert not _llvm_accepts(line), line


def test_body_and_structure_findings():
    blocks = mir.parse_body(HAND.read_text(), "axpy")
    # basic blocks: the fall-through of the conditional branch gets a generated label
    assert [b.label for b in blocks] == ["axpy", ".Lft0", ".Lend"] and [len(b.insts) for b in blocks] == [8, 9, 1]
    k = abi.make_kernel("axpy", blocks, AXPY_ARGS)
    assert verify.verify_kernel(k) == []
    assert (k.descriptor["next_free_vgpr"], k.descriptor["next_free_sgpr"], k.descriptor["accum_offset"]) == (6, 10, 8)
    assert k.descriptor["kernarg_size"] == 24 and [a[".offset"] for a in k.metadata[".args"]] == [0, 8, 16, 20]
    assert k.metadata[".sgpr_count"] == 16 and k.metadata[".vgpr_count"] == 6
    hidden = abi.make_kernel("axpy", blocks, AXPY_ARGS, hidden_args=True)        # amdclang's layout for the same arguments
    assert hidden.descriptor["kernarg_size"] == 280 and hidden.metadata[".args"][4][".offset"] == 24
    assert hidden.metadata[".args"][-1] == {".offset": 88, ".size": 2, ".value_kind": "hidden_grid_dims"}
    # structure
    bad = mir.parse_body("v_mov_b32_e32 v0, 0\ns_cbranch_execz .Lmissing\n")
    found = verify.verify_kernel(abi.make_kernel("k", bad, []))
    assert {f["kind"] for f in found} == {"illegal_instruction", "structure"}
    assert "undefined label" in found[0]["message"] and found[0]["block"] == "entry" and found[0]["index"] == 1
    assert "falls off" in found[1]["message"]
    with pytest.raises(mir.AsmError, match="line 2"):
        mir.parse_body("s_endpgm\nv_mov_b32_e32 v0, ,\n")


@needs_toolchain
@pytest.mark.parametrize("name", corpus.names())
def test_corpus_imports_verifies_and_reemits_identically(name):
    b = harness.reference_build(corpus.load(name))
    m = emit.import_asm(b.asm)
    k = m.kernel()
    assert verify.verify(m) == []
    text = mir.print_module(m)
    assert mir.print_module(mir.parse(text)) == text                        # the printed form is a fixed point
    built = emit.build(m)                                                    # includes the decode cross-check
    assert toolchain.section(built.hsaco, ".text") == toolchain.section(b.hsaco, ".text")
    ro, ro0 = toolchain.section(built.hsaco, ".rodata"), toolchain.section(b.hsaco, ".rodata")
    assert ro[:16] + ro[24:] == ro0[:16] + ro0[24:]                          # the descriptor, except the code offset
    assert toolchain.kernel_metadata(built.hsaco, k.name) == toolchain.kernel_metadata(b.hsaco, k.name)
    res = abi.resources(k)                                                   # recomputed from the instructions
    assert {x: k.descriptor[x] for x in ("next_free_vgpr", "next_free_sgpr", "accum_offset")} == \
           {x: res[x] for x in ("next_free_vgpr", "next_free_sgpr", "accum_offset")}
    assert {x: k.metadata["." + x] for x in ("vgpr_count", "agpr_count", "sgpr_count")} == \
           {x: res[x] for x in ("vgpr_count", "agpr_count", "sgpr_count")}


@needs_toolchain
def test_emit_errors_and_crosscheck():
    m = emit.import_asm(harness.reference_build(corpus.load("axpy")).asm)
    built = emit.build(m)
    other = emit.import_asm(built.asm)
    other.kernel().blocks[0].insts[4].mnemonic = "s_add_i32"                 # was s_mul_i32: same operands
    assert any("s_add_i32" in d for d in emit.crosscheck(other, built.hsaco))
    other.kernel().blocks[0].insts[4] = mir.parse_inst("v_add_u32_e32 v0, v1, s2")
    with pytest.raises(emit.EmitError, match="assembler rejected"):
        emit.build(other)


@pytest.mark.parametrize("_", [pytest.param(0, marks=gpu)])
def test_hand_written_kernel_passes_the_battery(_, agc_root):
    m = corpus.load("axpy")
    k = abi.make_kernel("axpy", mir.parse_body(HAND.read_text(), "axpy"), AXPY_ARGS)
    built = emit.build(abi.make_module([k]))
    r = harness.check(m, built.hsaco)
    assert r["ok"] and r["cases_run"] == r["cases_total"], r.get("failures") or r.get("error")
    assert r["resources"]["vgprs"] == 6 and r["resources"]["sgprs"] == 16
    p = harness.paired(m, harness.reference_build(m).hsaco, built.hsaco)
    assert p["ok"] and p["outcome"] == "parity" and 0.97 < p["speedup"] < 1.03, p
