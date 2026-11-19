import os
import subprocess
import sys
from pathlib import Path

import pytest

from agc.isa import table

XML = Path(os.environ.get("AGC_ISA_XML", Path.home() / "isa-spec" / "amdgpu_isa_cdna4.xml"))


def test_table_contents():
    isa = table()
    assert isa.source["architecture"] == "AMD CDNA 4" and isa.source["license"] == "MIT"
    assert len(isa.names()) == 1240
    mfma = [n for n in isa.names() if "MFMA" in isa.instruction(n).subgroups]
    assert "v_mfma_f32_16x16x32_bf16" in mfma and len(mfma) > 40
    assert "terminator" in isa.instruction("s_endpgm").flags
    assert {"branch", "cond_branch"} <= isa.instruction("s_cbranch_execz").flags
    assert isa.instruction("global_load_dword").group == "VMEM" and isa.instruction("s_load_dword").group == "SMEM"


def test_resolve_forms():
    isa = table()
    ins, form, encs = isa.resolve("v_add_u32_e32")
    assert ins.name == "v_add_u32" and form == "e32" and {e.enc for e in encs} == {"ENC_VOP2", "VOP2_INST_LITERAL"}
    assert [e.enc for e in isa.resolve("v_add_u32_e64")[2]] == ["ENC_VOP3"]
    assert [e.enc for e in isa.resolve("v_add_u32_dpp")[2]] == ["VOP2_VOP_DPP"]
    assert isa.resolve("v_add_u32") is None                 # LLVM requires the suffix
    assert isa.resolve("v_fma_f32")[1] == "" and isa.resolve("v_fma_f32_e32") is None
    assert isa.resolve("v_fmaak_f32")[2][0].enc == "VOP2_INST_LITERAL"
    assert isa.resolve("s_and_saveexec_b64")[0].group == "SALU" and isa.resolve("v_nonsense_e32") is None


def test_operands_and_types():
    isa = table()
    enc = isa.resolve("global_load_dword")[2][0]
    assert [(o.field, o.size) for o in enc.explicit] == [("VDST", 32), ("ADDR", 64), ("SADDR", 64)]
    assert [o.type for o in enc.implicit] == ["OPR_GPUMEM", "OPR_SDST_M0"]
    cnd = isa.resolve("v_cndmask_b32_e32")[2][0]
    assert cnd.explicit[-1].type == "OPR_VCC" and not cnd.explicit[-1].coded
    assert isa.type_classes("OPR_VGPR") == {"v"} and isa.type_classes("OPR_VGPR_OR_ACCVGPR") == {"v", "a"}
    assert {"s", "v", "const", "literal", "vcc", "exec", "m0", "scc"} <= isa.type_classes("OPR_SRC")
    assert "literal" not in isa.type_classes("OPR_SRC_NOLIT") and "v" not in isa.type_classes("OPR_SSRC")
    assert {"0", "64", "-16", "1.0", "-4.0", "0.15915494"} <= isa.inline_constants("OPR_SRC")
    assert "65" not in isa.inline_constants("OPR_SRC")


def test_decode_known_words():
    isa = table()
    words = [0xBF810000,                      # s_endpgm
             0xBF8C0F70,                      # s_waitcnt vmcnt(0)
             0x7E0002FF, 0x3F800000,          # v_mov_b32_e32 v0, <literal>
             0xDC508000, 0x047F0002,          # global_load_dword v4, v[2:3], off
             0x680A0900]                      # v_add_u32_e32 v5, v0, v4  (word order: op | vdst | vsrc1 | src0)
    code = b"".join(w.to_bytes(4, "little") for w in words)
    got = isa.decode(code)
    assert [(g[1], g[3]) for g in got] == [("s_endpgm", 4), ("s_waitcnt", 4), ("v_mov_b32", 8),
                                           ("global_load_dword", 8), ("v_add_u32", 4)]
    assert isa.decode((0xFFFFFFFF).to_bytes(4, "little")) == []


@pytest.mark.skipif(not XML.exists(), reason="the ISA XML is not on this machine")
def test_generated_file_is_current(tmp_path):
    """`agc/isa/cdna4.json.gz` is exactly what `scripts/gen_isa.py` produces from the XML."""
    import scripts_gen_isa as gen
    out = tmp_path / "isa.json.gz"
    gen.OUT = out
    assert gen.main([str(XML)]) == 0
    assert out.read_bytes() == (Path(gen.__file__).parent.parent / "agc" / "isa" / "cdna4.json.gz").read_bytes()
