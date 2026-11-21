"""The `coarsen` pass: several workgroups of the original per launched workgroup."""
import pytest

from agc import mir
from agc.mir import abi, check, coarsen
from agc.mir.loops import NotApplicable
from agc.session import Session, SessionError
from conftest import KERNELS, gpu, needs_toolchain

AXPY = """
    s_load_dwordx2 s[4:5], s[0:1], 0x10
    s_mov_b32 s3, 0
    s_lshl_b64 s[2:3], s[2:3], 8
    v_mov_b32_e32 v1, 0
    v_lshl_add_u64 v[0:1], s[2:3], 0, v[0:1]
    s_waitcnt lgkmcnt(0)
    s_ashr_i32 s3, s5, 31
    s_mov_b32 s2, s5
    v_cmp_gt_i64_e32 vcc, s[2:3], v[0:1]
    s_and_saveexec_b64 s[2:3], vcc
    s_cbranch_execz .Ldone
    s_load_dwordx4 s[0:3], s[0:1], 0x0
    v_lshlrev_b64 v[0:1], 2, v[0:1]
    s_waitcnt lgkmcnt(0)
    v_lshl_add_u64 v[2:3], s[2:3], 0, v[0:1]
    v_lshl_add_u64 v[0:1], s[0:1], 0, v[0:1]
    global_load_dword v4, v[2:3], off
    global_load_dword v5, v[0:1], off
    s_waitcnt vmcnt(0)
    v_fmac_f32_e32 v4, s4, v5
    global_store_dword v[2:3], v4, off
.Ldone:
    s_endpgm
"""
ARGS = [abi.Arg("global_buffer"), abi.Arg("global_buffer"), abi.Arg("by_value", 4), abi.Arg("by_value", 4)]


def kernel(body, args=ARGS, **kw):
    return abi.make_kernel("k", mir.parse_body(body, "k"), list(args), **kw)


def test_coarsen_wraps_the_body_and_appends_the_grid_argument():
    k = kernel(AXPY)
    r = coarsen.coarsen(k, 4)
    abi.sync_resources(k)
    assert r["arg_offset"] == 24 and k.descriptor["kernarg_size"] == 32 and k.metadata[".kernarg_segment_size"] == 32
    assert k.metadata[".args"][-1] == {".offset": 24, ".size": 4, ".value_kind": "by_value"}
    text = [str(i) for i in k.insts()]
    assert text.count("s_endpgm") == 1 and text[-1] == "s_endpgm"                     # one exit, after the loop
    assert "s_load_dword s10, s[0:1], 0x18" in text                                    # the original grid_x
    assert "s_lshl_b32 s9, s2, 2" in text and "s_cmp_lt_u32 s8, 4" in text              # base = 4 * workgroup id, 4 iterations
    labels = [b.label for b in k.blocks]
    head = labels.index(coarsen.HEAD)
    # every iteration starts from the entry state: exec, the kernarg pointer and the workitem id are restored
    restored = [str(i) for b in k.blocks[head:labels.index(coarsen.BODY)] for i in b.insts]
    assert {"s_mov_b64 exec, s[6:7]", "s_mov_b32 s0, s11", "s_mov_b32 s1, s12", "v_mov_b32_e32 v0, v6"} <= set(restored)
    assert "s_add_u32 s2, s9, s8" in restored and "s_cmp_ge_u32 s2, s10" in restored    # the virtual id, bounded by grid_x
    assert check.static_check(abi.make_module([k]), encode=False)["ok"]


def test_coarsen_ends_each_virtual_workgroup_with_a_barrier_when_lds_is_shared():
    """Two waves of one workgroup: without the barrier the faster wave starts the next virtual workgroup and
    overwrites LDS the other still reads (kda_step failed the battery this way)."""
    def latch(body):
        k = kernel(body)
        coarsen.coarsen(k, 2)
        return [str(i) for i in k.blocks[[b.label for b in k.blocks].index(coarsen.LATCH)].insts]
    assert "s_barrier" not in latch(AXPY)
    lds = AXPY.replace("    global_store_dword v[2:3], v4, off\n", "    ds_write_b32 v0, v4\n    global_store_dword v[2:3], v4, off\n")
    assert latch(lds)[0] == "s_barrier"


def test_coarsen_uses_a_multiply_for_other_factors_and_refuses_twice():
    k = kernel(AXPY)
    coarsen.coarsen(k, 3)
    assert "s_mul_i32 s9, s2, 3" in [str(i) for i in k.insts()]
    with pytest.raises(NotApplicable, match="already coarsened"):
        coarsen.coarsen(k, 2)
    with pytest.raises(NotApplicable, match="at least 2"):
        coarsen.coarsen(kernel(AXPY), 1)


def test_coarsen_refuses_an_exit_that_skips_a_barrier():
    body = """
    v_cmp_gt_u32_e32 vcc, 5, v0
    s_and_saveexec_b64 s[4:5], vcc
    s_cbranch_execz .Ldone
    s_barrier
.Ldone:
    s_endpgm
"""
    with pytest.raises(NotApplicable, match="s_barrier"):
        coarsen.coarsen(kernel(body, []), 2)
    ok = kernel("    s_barrier\n    v_mov_b32_e32 v1, v0\n    s_endpgm\n", [])
    coarsen.coarsen(ok, 2)                                                          # every wave passes the barrier


def test_coarsen_redirects_the_read_of_grid_dim_x():
    body = """
    s_load_dword s4, s[0:1], 0x8
    s_load_dwordx2 s[6:7], s[0:1], 0x0
    s_waitcnt lgkmcnt(0)
    v_mov_b32_e32 v1, s4
    s_endpgm
"""
    k = abi.make_kernel("k", mir.parse_body(body, "k"), [abi.Arg("global_buffer")], hidden_args=True)
    hidden = next(a[".offset"] for a in k.metadata[".args"] if a[".value_kind"] == "hidden_block_count_x")
    assert hidden == 8
    r = coarsen.coarsen(k, 2)
    assert r["redirected_grid_reads"] == 1 and f"s_load_dword s4, s[0:1], {hex(r['arg_offset'])}" in [str(i) for i in k.insts()]
    wide = body.replace("s_load_dword s4, s[0:1], 0x8", "s_load_dwordx2 s[4:5], s[0:1], 0x8")
    with pytest.raises(NotApplicable, match="together with other arguments"):
        coarsen.coarsen(abi.make_kernel("k", mir.parse_body(wide, "k"), [abi.Arg("global_buffer")], hidden_args=True), 2)
    copied = body.replace("s_load_dword s4, s[0:1], 0x8", "s_mov_b32 s4, s0")
    with pytest.raises(NotApplicable, match="other than as the base"):
        coarsen.coarsen(abi.make_kernel("k", mir.parse_body(copied, "k"), [abi.Arg("global_buffer")], hidden_args=True), 2)


@pytest.mark.parametrize("name", [pytest.param("axpy", marks=gpu), pytest.param("row_sum", marks=gpu)])
def test_coarsen_is_bit_identical_on_the_gpu(name, tmp_path):
    s = Session.open(KERNELS / f"{name}.json", tmp_path, quick=True)
    st = s.apply("ref", "coarsen", {"factor": 4})
    launch = s.launch_of(st["id"])
    assert launch["grid"][0].startswith("cdiv(") and launch["args"][0]["dtype"] == "u32"
    assert not s.generated(st["id"]) and s.static_check(st["id"])["ok"]
    assert s.check(st["id"])["ok"]                                                  # the battery, tails and shape variants included


@needs_toolchain
def test_coarsen_refusal_is_a_parameter_error(tmp_path):
    s = Session.open(KERNELS / "gemm_tiled.json", tmp_path, quick=True)
    with pytest.raises(SessionError, match="s_barrier") as e:
        s.apply("ref", "coarsen", {"factor": 2})
    assert e.value.kind == "parameter"


def test_coarsen_accepts_an_early_exit_every_wave_of_the_workgroup_takes_together():
    """`if (alpha == 0) return;` before a barrier: decided by a kernel argument, the same in all waves."""
    def body(test):
        return f"""
    s_load_dwordx2 s[4:5], s[0:1], 0x10
    s_waitcnt lgkmcnt(0)
{test}
    s_barrier
    v_mov_b32_e32 v1, v0
.Ldone:
    s_endpgm
"""
    scalar = "    s_cmp_eq_u32 s4, 0\n    s_cbranch_scc1 .Ldone"
    mask = ("    v_cmp_eq_f32_e64 s[6:7], s4, 0\n    v_cmp_eq_f32_e64 s[8:9], s5, 1.0\n    s_and_b64 s[6:7], s[6:7], s[8:9]\n"
            "    s_and_b64 vcc, exec, s[6:7]\n    s_cbranch_vccnz .Ldone")
    for test in (scalar, mask):
        k = kernel(body(test))
        coarsen.coarsen(k, 2)
        assert [str(i) for i in k.blocks[[b.label for b in k.blocks].index(coarsen.LATCH)].insts][0] == "s_barrier"
    per_lane = "    v_cmp_eq_u32_e32 vcc, s4, v0\n    s_cbranch_vccnz .Ldone"                 # depends on the workitem id
    loaded = ("    s_load_dword s6, s[4:5], 0x0\n    s_waitcnt lgkmcnt(0)\n    s_cmp_eq_u32 s6, 0\n"
              "    s_cbranch_scc1 .Ldone")                                                   # memory the kernel may write
    after = ("    v_cmp_eq_u32_e32 vcc, s4, v0\n    s_cbranch_vccz .Lskip\n    s_mov_b32 s4, 0\n.Lskip:\n"
             "    s_cmp_eq_u32 s4, 0\n    s_cbranch_scc1 .Ldone")                             # a value set under a per-wave branch
    for test in (per_lane, loaded, after):
        with pytest.raises(NotApplicable, match="workgroup-uniform"):
            coarsen.coarsen(kernel(body(test)), 2)


def test_coarsen_follows_an_offset_copy_of_the_kernarg_pointer_and_accepts_scratch():
    body = """
    s_add_u32 s24, s0, 0x60
    s_addc_u32 s25, s1, 0
    s_load_dword s4, s[24:25], 0x4
    s_waitcnt lgkmcnt(0)
    v_mov_b32_e32 v1, s4
    scratch_store_dword off, v1, off offset:4
    scratch_load_dword v2, off, off offset:4
    s_waitcnt vmcnt(0)
    s_endpgm
"""
    args = [abi.Arg("global_buffer")] * 12 + [abi.Arg("hidden_block_count_x", 4), abi.Arg("hidden_block_count_y", 4)]
    k = kernel(body, args)
    coarsen.coarsen(k, 2)                                                           # 0x60 + 4 is gridDim.y: not redirected
    k = kernel(body.replace("s[24:25], 0x4", "s[24:25], 0x0"), args)
    with pytest.raises(NotApplicable, match="gridDim.x"):
        coarsen.coarsen(k, 2)
    k = kernel(body.replace("s_addc_u32 s25, s1, 0\n", "s_mov_b32 s25, s1\n"), args)
    with pytest.raises(NotApplicable, match="other than as the base"):
        coarsen.coarsen(k, 2)


@needs_toolchain
def test_throttle_keeps_the_code_and_reserves_lds_for_n_workgroups_per_cu(tmp_path):
    from agc.arch.model import load as load_arch
    arch = load_arch()
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    st = s.apply("ref", "throttle", {"workgroups_per_cu": 4})
    assert s.store.get(st["id"]).ir == s.store.get(s.ref_id).ir
    lds = s.launch_of(st["id"])["lds"]
    assert arch.res("lds_per_cu") // lds == 4 and lds % arch.res("lds_granule") == 0
    with pytest.raises(SessionError, match="at least 1"):
        s.apply("ref", "throttle", {"workgroups_per_cu": 0})


@needs_toolchain
def test_stream_loads_marks_every_vector_load_non_temporal(tmp_path):
    s = Session.open(KERNELS / "axpy.json", tmp_path, quick=True)
    st = s.apply("ref", "stream_loads")
    loads = [l for l in s.store.get(st["id"]).ir.splitlines() if "global_load_" in l]
    stores = [l for l in s.store.get(st["id"]).ir.splitlines() if "global_store_" in l]
    assert loads and all(l.rstrip().endswith("sc0 sc1 nt") for l in loads) and not any(" nt" in l for l in stores)
    assert s.static_check(st["id"])["ok"]
    with pytest.raises(SessionError, match="marked already"):
        s.apply(st["id"], "stream_loads")
