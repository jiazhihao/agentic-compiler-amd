from agc.runtime import toolchain
from conftest import KERNELS, needs_toolchain

pytestmark = needs_toolchain


def test_hip_build_and_metadata():
    b = toolchain.hip_build(KERNELS / "axpy.hip")
    assert ".amdhsa_kernel axpy" in b.asm and 'amdgcn_target "amdgcn-amd-amdhsa--gfx950"' in b.asm
    k = toolchain.kernel_metadata(b.hsaco, "axpy")
    assert k[".wavefront_size"] == 64 and [a[".offset"] for a in k[".args"][:4]] == [0, 8, 16, 20]
    assert toolchain.hip_build(KERNELS / "axpy.hip").key == b.key          # cached
    assert toolchain.identity()["clang"] and toolchain.identity()["rocm"]


def test_assemble_reproduces_amdclang_text():
    """The assembler only encodes: amdclang's own assembly gives amdclang's own `.text`."""
    b = toolchain.hip_build(KERNELS / "axpy.hip")
    again = toolchain.assemble(b.asm)
    assert toolchain.section(again, ".text") == toolchain.section(b.hsaco, ".text")
    assert toolchain.kernel_metadata(again, "axpy") == toolchain.kernel_metadata(b.hsaco, "axpy")
    assert "v_fmac_f32" in toolchain.disassemble(again)
    assert any(s["name"] == "axpy" and s["type"] == "FUNC" for s in toolchain.symbols(again))
