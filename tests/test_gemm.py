"""M7: GEMM on MFMA. Operand layouts measured on the device, the MFMA template, and the comparison
with amdclang and hipBLASLt."""
import json
from pathlib import Path

import numpy as np
import pytest

from agc import corpus, gen, mir, tair
from agc.arch.model import load as load_arch
from agc.manifest import Manifest
from agc.mir import abi, check, passes
from conftest import KERNELS, gpu, needs_toolchain

PROBES = Path(__file__).parent / "probes"
RECORD = corpus.BASELINES.with_name("gemm-gfx950.json")


def test_tair_einsum():
    p = tair.parse((KERNELS / "gemm_bf16.tair").read_text())
    assert p.body[0].einsum == "mk,nk->mn" and tair.parse(tair.print_program(p)) == p and p.ranks()["C"] == "full"
    a, b = np.arange(12.0).reshape(3, 4), np.arange(8.0).reshape(2, 4)
    assert np.array_equal(tair.evaluate(p, {"A": a, "B": b}, np.float64)["C"], a @ b.T)
    assert gen.applicable(corpus.load("gemm_bf16")) == ["gemm_mfma"]


def _probe(mnemonic: str, dst_regs: int) -> bytes:
    """One MFMA on operands loaded lane by lane, the result stored lane by lane: written in mir."""
    body = f"""
        s_load_dwordx4 s[4:7], s[0:1], 0
        s_load_dwordx2 s[8:9], s[0:1], 16
        v_lshlrev_b32_e32 v1, 4, v0
        global_load_dwordx4 v[2:5], v1, s[4:5]
        global_load_dwordx4 v[6:9], v1, s[6:7]
        {mnemonic} v[10:{9 + dst_regs}], v[2:5], v[6:9], 0
        v_mov_b32_e32 v26, 0
        v_mov_b32_e32 v27, 0
        v_mov_b32_e32 v28, 0
        v_mov_b32_e32 v29, 0
        v_lshlrev_b32_e32 v1, 6, v0
    """
    for i in range(4):
        regs = f"v[{10 + 4 * i}:{13 + 4 * i}]" if 4 * i < dst_regs else "v[26:29]"
        body += f"global_store_dwordx4 v1, {regs}, s[8:9]" + (f" offset:{16 * i}" if i else "") + "\n"
    k = abi.make_kernel("mfma_layout", mir.parse_body(body + "s_endpgm\n", "mfma_layout"), [abi.Arg("global_buffer")] * 3)
    passes.legalize(k)
    abi.sync_resources(k)
    r = check.static_check(abi.make_module([k]), strict=True)
    assert r["ok"], r["findings"]
    return r["built"].hsaco


@pytest.mark.parametrize("mnemonic, fn, regs", [pytest.param("v_mfma_f32_32x32x16_bf16", "mfma_32x32x16", 16, marks=gpu),
                                                 pytest.param("v_mfma_f32_16x16x32_bf16", "mfma_16x16x32", 4, marks=gpu)])
def test_mfma_layouts_on_the_device(mnemonic, fn, regs, agc_root):
    """The layouts in the arch data (`mfma.layouts`, source `measured`) are what the hardware does:
    a hand-written probe kernel matches the layout model exactly on the whole battery."""
    from agc.runtime import harness
    d = json.loads((PROBES / "mfma_layout.json").read_text())
    d["reference"]["function"] = fn
    for p in d["params"][:2]:
        p.pop("init")                                        # every distribution of the battery
    m = Manifest.from_dict(d, PROBES / "mfma_layout.json")
    lay = load_arch().data["mfma"]["layouts"][mnemonic]
    assert lay["source"] == "measured" and lay["value"]["dst_regs"] == regs
    d2 = dict(d, tolerance={"d": {"rtol": 1e-6, "atol": 0.0, "cond": 2e-6}})      # rounding of a 16- or 32-term dot product
    r = harness.check(Manifest.from_dict(d2, PROBES / "mfma_layout.json"), _probe(mnemonic, regs))
    assert r["ok"] and r["cases_run"] == r["cases_total"], r.get("failures") or r.get("error")


@needs_toolchain
@pytest.mark.parametrize("tiles, unroll", [(1, 1), (2, 2), (4, 1)])
def test_gemm_variants_are_statically_clean(tiles, unroll):
    m = corpus.load("gemm_bf16")
    c = gen.generate(m, "gemm_mfma", {"tiles": tiles, "unroll": unroll})
    r = check.static_check(c.module, strict=True)
    assert r["ok"] and not r["findings"], r["findings"][:3]
    k = c.module.kernel()
    insts = list(k.insts())
    assert sum(i.mnemonic == "v_mfma_f32_32x32x16_bf16" for i in insts) == tiles * tiles * (unroll + (unroll > 1))
    assert k.metadata[".agpr_count"] == 16 * tiles * tiles and k.descriptor["accum_offset"] % 4 == 0
    assert sum(i.mnemonic == "global_store_dword" for i in insts) == 16 * tiles * tiles
    assert c.launch == {"grid": [f"cdiv(N, {32 * tiles})", f"cdiv(M, {32 * tiles})"], "block": [64], "lds": 0}
    assert k.descriptor["system_sgpr_workgroup_id_y"] == 1 and "s_barrier" not in mir.print_kernel_body(k)
    with pytest.raises(gen.GenError, match="tiles must be"):
        gen.generate(m, "gemm_mfma", {"tiles": 4, "unroll": 2}) and gen.gemm.generate(m, gen.program_of(m), tiles=3)


def test_gemm_needs_k_multiple_of_16():
    d = json.loads((KERNELS / "gemm_bf16.json").read_text())
    d["shapes"]["K"] = 250
    with pytest.raises(gen.GenError, match="multiple of 16"):
        gen.generate(Manifest.from_dict(d, KERNELS / "gemm_bf16.json"), "gemm_mfma")


def test_recorded_gemm_results():
    """`scripts/gemm.py`: full battery for every variant; three large shapes and a small one."""
    rec = json.loads(RECORD.read_text())
    assert all(v["static"] and v["battery"] == "77/77" for v in rec["variants"]) and len(rec["variants"]) == 6
    assert set(rec["shapes"]) == {"square", "wide", "tall", "small"}
    for name, s in rec["shapes"].items():
        b = s["best"]
        assert b["outcome"] == "win" and b["vs_amdclang_ci95"][0] > 100, name       # amdclang emits no MFMA
        assert s["hipblaslt_ms"] and 1.0 < b["hipblaslt_ratio"] < 3.5, name          # behind the library: reported, not hidden
    assert rec["shapes"]["square"]["best"]["tflops"] > 400


@pytest.mark.parametrize("_", [pytest.param(0, marks=gpu)])
def test_gemm_on_the_device(_, tmp_path):
    from agc.runtime import baselines
    from agc.session import Session
    s = Session.open(KERNELS / "gemm_bf16.json", tmp_path)
    g = s.generate("gemm_mfma", {"tiles": 2, "unroll": 1})
    c = s.check(g["id"])
    assert c["ok"] and c["cases_run"] == c["cases_total"] > 50, c
    b = s.bench(g["id"])
    assert b["outcome"] == "win" and b["speedup_ci95"][0] > 50, b
    if baselines.hipblaslt_available():
        lib = baselines.hipblaslt_gemm(2048, 2048, 2048, samples=30)
        assert lib["ok"] and 0.005 < lib["median_ms"] < b["candidate_ms"], lib       # the library is still ahead
        rect = baselines.hipblaslt_gemm(1024, 3072, 2048, samples=20)
        assert rect["ok"], rect
