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


SHARED = [("gemm_bf16", {"tiles": 4, "unroll": 1, "share": 1}), ("gemm_bf16", {"tiles": 4, "unroll": 1, "share": 2}),
          ("gemm_bf16", {"tiles": 2, "unroll": 2, "share": 2}), ("gemm_bf16", {"tiles": 4, "unroll": 1, "share": 3}),
          ("gemm_fp8", {"tiles": 2, "unroll": 1, "share": 0}), ("gemm_fp8", {"tiles": 4, "unroll": 1, "share": 1}),
          ("gemm_fp8", {"tiles": 4, "unroll": 1, "share": 2}), ("gemm_fp8", {"tiles": 4, "unroll": 1, "share": 2, "wide": 1}),
          ("gemm_fp8", {"tiles": 2, "unroll": 2, "share": 2, "wide": 1})]


@needs_toolchain
@pytest.mark.parametrize("name, params", SHARED)
def test_shared_and_fp8_variants_are_statically_clean(name, params):
    """Operands through LDS in a 4-wave workgroup (share 1: one half each; 2: both, loaded in row pieces; 3: loads
    straight into LDS), and FP8 inputs (the 32x32x16 FP8 MFMA; `wide`: the 32x32x64 one)."""
    m = corpus.load(name)
    c = gen.generate(m, "gemm_mfma", params)
    r = check.static_check(c.module, strict=True)
    assert r["ok"] and not r["findings"], r["findings"][:3]
    k = c.module.kernel()
    body = mir.print_kernel_body(k)
    T, share = params["tiles"], params["share"]
    span = 32 * T * (2 if share else 1)
    assert c.launch == {"grid": [f"cdiv(N, {span})", f"cdiv(M, {span})"], "block": [256 if share else 64], "lds": 0}
    assert ("s_barrier" in body) == bool(share) and (k.descriptor["group_segment_fixed_size"] > 0) == bool(share)
    assert k.descriptor["group_segment_fixed_size"] <= load_arch().res("lds_per_cu")
    mfma = ("v_mfma_f32_32x32x64_f8f6f4" if params.get("wide") else "v_mfma_f32_32x32x16_fp8_fp8") if name == "gemm_fp8" else "v_mfma_f32_32x32x16_bf16"
    assert mfma in body and ("global_load_lds_dwordx4" in body) == (share == 3)
    if share == 2:                                           # every load from memory is 16 bytes per lane, whatever the element
        assert "global_load_dwordx2" not in body and "global_load_dwordx4" in body


def test_shared_and_fp8_refusals():
    bf, fp = corpus.load("gemm_bf16"), corpus.load("gemm_fp8")
    for m, params, msg in ((bf, {"tiles": 1, "share": 2}, "tiles of 2 or 4"), (bf, {"tiles": 4, "share": 2, "wide": 1}, "FP8 inputs"),
                           (fp, {"tiles": 4, "share": 1, "wide": 1}, "share=2"), (fp, {"tiles": 4, "share": 3}, "bf16 only")):
        with pytest.raises(gen.GenError, match=msg):
            gen.generate(m, "gemm_mfma", params)
    d = json.loads((KERNELS / "gemm_fp8.json").read_text())
    d["shapes"]["K"] = 240                                   # a multiple of 16 but not of 64
    m = Manifest.from_dict(d, KERNELS / "gemm_fp8.json")
    assert gen.generate(m, "gemm_mfma", {"tiles": 4, "share": 2}).module is not None
    with pytest.raises(gen.GenError, match="multiple of 64"):
        gen.generate(m, "gemm_mfma", {"tiles": 4, "share": 2, "wide": 1})


@pytest.mark.parametrize("name, params", [pytest.param(n, p, marks=gpu) for n, p in SHARED])
def test_shared_and_fp8_variants_pass_the_battery(name, params, tmp_path):
    from agc.session import Session
    s = Session.open(KERNELS / f"{name}.json", tmp_path)
    c = s.check(s.generate("gemm_mfma", params)["id"])
    assert c["ok"] and c["cases_run"] == c["cases_total"] > 50, c


@pytest.mark.parametrize("wide", [pytest.param(0, marks=gpu), pytest.param(1, marks=gpu)])
def test_e5m2_inputs_pass_the_battery(wide, tmp_path):
    """The other OCP FP8 format: the `bf8` MFMA, and `cbsz` / `blgp` 1 on the wide one. No HIP source: the
    reference is the einsum."""
    from agc.session import Session
    d = json.loads((KERNELS / "gemm_fp8.json").read_text())
    d.pop("source")
    d["name"] = "gemm_e5m2"
    for p in d["params"]:
        if p["dtype"] == "e4m3":
            p["dtype"] = "e5m2"
    d["program"] = {"text": (KERNELS / "gemm_fp8.tair").read_text().replace("e4m3", "e5m2")}
    s = Session.from_manifest(Manifest.from_dict(d, KERNELS / "gemm_fp8.json"), tmp_path)
    c = s.check(s.generate("gemm_mfma", {"tiles": 4, "unroll": 1, "share": 2, "wide": wide})["id"])
    assert c["ok"] and c["cases_run"] == c["cases_total"] > 50, c


def test_gemm_needs_k_multiple_of_16():
    d = json.loads((KERNELS / "gemm_bf16.json").read_text())
    d["shapes"]["K"] = 250
    with pytest.raises(gen.GenError, match="multiple of 16"):
        gen.generate(Manifest.from_dict(d, KERNELS / "gemm_bf16.json"), "gemm_mfma")


def test_recorded_gemm_results():
    """`scripts/gemm.py`: full battery for every variant; three large shapes and a small one. With the operands
    shared through LDS (#23) the template is within 1.7x of hipBLASLt's time on every shape (2.5x to 2.8x before)."""
    rec = json.loads(RECORD.read_text())
    assert all(v["static"] and v["battery"] == "77/77" for v in rec["variants"]) and len(rec["variants"]) == 17
    assert {v["params"]["share"] for v in rec["variants"]} == {0, 1, 2, 3}
    assert set(rec["shapes"]) == {"square", "wide", "tall", "small"}
    for name, s in rec["shapes"].items():
        b = s["best"]
        assert b["outcome"] == "win" and b["vs_amdclang_ci95"][0] > 100, name       # amdclang emits no MFMA
        assert s["hipblaslt_ms"] and 1.0 < b["hipblaslt_ratio"] < 1.7, name          # behind the library: reported, not hidden
        assert b["params"]["share"] == 2, name
        unshared = min(r["ms"] for r in s["agc"] if r["params"]["share"] == 0)
        assert unshared / b["ms"] > 1.5, name
    assert rec["shapes"]["square"]["best"]["tflops"] > 750


def test_recorded_fp8_gemm_results():
    """`scripts/gemm.py gemm_fp8` (#75): every variant on the full battery; the 32x32x64 FP8 MFMA with LDS-shared
    operands is the fastest on every shape and within 1.4x of hipBLASLt's FP8 time."""
    rec = json.loads(RECORD.with_name("gemm-fp8-gfx950.json").read_text())
    assert "e4m3" in rec["operation"] and len(rec["variants"]) == 17
    assert all(v["static"] and v["battery"] == "77/77" for v in rec["variants"])
    for name, s in rec["shapes"].items():
        b = s["best"]
        assert b["outcome"] == "win" and b["params"]["share"] == 2 and b["params"]["wide"] == 1, name
        assert s["hipblaslt_ms"] and 1.0 < b["hipblaslt_ratio"] < 1.4, name
    assert rec["shapes"]["square"]["best"]["tflops"] > 1300
    m = corpus.load("gemm_fp8")
    assert m.tolerance["C"]["cond"] == 2.5e-4                 # the FP8 MFMA is less precise than an f32 sum (see the manifest's note)


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
