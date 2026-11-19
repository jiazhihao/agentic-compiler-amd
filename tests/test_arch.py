from agc.arch.model import load


def test_sources_tagged():
    arch = load()
    assert arch.name == "gfx950"
    for sec in ("resources", "peaks", "waitcnt"):
        for key, v in arch.section(sec).items():
            assert v.source in ("isa-doc", "rocminfo", "llvm", "measured"), (sec, key)


def test_occupancy():
    arch = load()
    # amdclang's AXPY: 6 VGPRs, 12 SGPRs -> the hardware limit of 8 waves per SIMD ("; Occupancy: 8")
    o = arch.occupancy(arch_vgprs=6, sgprs=12)
    assert o["waves_per_simd"] == 8 and o["limiter"] == "hardware"
    # 512 registers per lane per SIMD: 128 VGPRs leave room for 4 waves, 129 round up to 136 -> 3
    assert arch.occupancy(arch_vgprs=128)["waves_per_simd"] == 4
    assert arch.occupancy(arch_vgprs=129)["waves_per_simd"] == 3
    assert arch.occupancy(arch_vgprs=129)["limiter"] == "vgpr"
    # AGPRs share the file and start at accum_offset = align(arch_vgprs, 4)
    assert arch.accum_offset(6) == 8 and arch.accum_offset(1) == 4
    assert arch.vgpr_alloc(30, 96) == 128
    assert arch.occupancy(arch_vgprs=30, agprs=96)["waves_per_simd"] == 4
    # LDS: a 64 KB workgroup of 4 waves fits twice in 160 KB -> 8 waves per CU -> 2 per SIMD
    o = arch.occupancy(arch_vgprs=16, lds_bytes=65536, workgroup_size=256)
    assert o["waves_per_simd"] == 2 and o["limiter"] == "lds"
