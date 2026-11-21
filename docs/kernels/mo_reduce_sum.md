# `mo_reduce_sum`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 06:48

**Harness verdict:** fallback: the named state 1fd8f8152cfc9ea2 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 0.333) on 50 cases

## mo_reduce_sum: at the memory floor (single-touch case)

Baseline `1fd8f8152cfc9ea2` (amdclang, -ffast-math, EPL=4, block 64, grid cdiv(N,256)): 111 instructions, loop-free. Hot path: 3 scalar kernarg loads, ~17 VALU of 64-bit per-lane addressing and the range test, **one `global_load_dwordx4` per lane (1 KB per wave) with `s_waitcnt vmcnt(0)`**, `v_pk_add_f32` + `v_add_f32`, then 6 `ds_bpermute_b32` steps each with `s_waitcnt lgkmcnt(0)`, one `global_store_dword` from lane 0. The tail path (4 masked dword loads) runs only in the last workgroup.

Every input element is read exactly once (268.4 MB read, 1 MB written): this is the single-touch case, headroom 1.06 against the copy model.

### Time split (N = 2^26, 84.4 us)
| probe | state | time |
|---|---|---|
| full kernel | baseline | 84.4 us |
| launch only (`s_endpgm` first), 262144 one-wave workgroups | a085f65949787a8d | 58.1 us |
| no x4 load / wait | 528fbc9bb72cc025 | 61.5 us |
| no wave reduction, no store | 0cc42448664051f5 | 86.2 us |

The reduction and store cost nothing. The load adds only ~23 us over an empty dispatch, but the two are not additive: with 4x fewer workgroups (launch far cheaper) the kernel is slower. Dispatch (58 us) and the cold read (268 MB at ~4.2 TB/s ≈ 64 us + fixed) are overlapping bounds of nearly the same size, and the read is the one that binds.

### ISA differences tried against amdclang's code
The hand-written bodies replace 64-bit per-lane address VALU by scalar `s_lshl_b64`/`s_add_u32`/`s_addc_u32` with `global_load_dwordx4 v, v_off, s[4:5]`, the `saveexec` tail regions by a scalar `s_sub_u32`/`s_subb_u32` branch, and the 6 `ds_bpermute_b32` + 6 `lgkmcnt` waits by 4 `v_add_f32_dpp`; the 4-output variant stores all four results with one `global_store_dword` under exec 0x0001000100010001 (no `v_readlane`). None of this is in the time.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| LDS reservation 4 KB, 16 waves/CU (rb_nrm2 optimum) | +2 % | 975593dc4eb5b4a5 0.998 (0.994..1.007) | parity |
| LDS 2.7 KB, 24 waves/CU | +1 % | 9d54bf97e74c9376 1.000 (0.996..1.004) | parity |
| LDS 8 KB, 8 waves/CU | ? | f39988d21cc54fa7 0.864 (0.861..0.868) | loss |
| 4 outputs/wave, 4 x4 loads in flight, DPP rows stored directly, 1/4 workgroups | up to 58 us of dispatch | a264b0e365e1a3bf 0.922 (0.917..0.927) | loss |
| same + 4 waves/CU | | 8c6164d3eb3cd2ab 0.977 (0.971..0.985) | loss |
| same + 8 waves/CU | | 34a220e13f0de754 0.962 (0.956..0.969) | loss |
| same + 2 waves/CU | | 5c03c8f1ab1c66f4 0.988 (0.983..0.992) | parity/slight loss |
| 2 outputs/wave, 2 x4 loads in flight, 1/2 workgroups | | 33cdbd815f567a5c 0.972 (0.966..0.981) | loss |
| block-256 DPP body + 16 waves/CU | +2 % | 61c206f45a1aa9a7 0.989 (0.984..0.999) | parity |
| (earlier) coarsen 2 / 4 / 8 | | 0.987 / 0.946 / 0.899 | parity / loss / loss |
| (earlier) scalar addressing + DPP, block 64 / block 256 | | 0.992 / 0.993 | parity |

### Untested
- Block 512/1024 with 1 KB per wave and an LDS reservation (the rb_dot plateau at 40 KB): block 256 at 16 waves/CU was already parity, so not expected to differ.
- Pipelined waits inside the multi-load bodies: the bodies lose on bytes per wave, not on the wait.
- Nothing reads fewer bytes: the output needs every input element once, so 1.5x is out of reach in principle (headroom 1.06).

`baseline` is shipped; it is amdclang's own build, so `equivalent` against `ref` was not re-run for a new state (the reduction order differs from `ref` and is within tolerance, as the baseline's battery shows).

### Tried

| what | outcome | speedup |
|---|---|---|
| LDS reservation 4096 B on amdclang's code (16 one-wave workgroups per CU instead of 32) | parity | 0.9976 |
| LDS reservation 2730 B (24 waves per CU) | parity | 1 |
| LDS reservation 8192 B (8 waves per CU) | loss | 0.8643 |
| hand-written: one wave owns 4 outputs (4 KB), 16 lanes per output, 4 global_load_dwordx4 in flight, one wait, 4 DPP steps, masked store from lanes 0/16/32/48; grid cdiv(N,1024) | loss | 0.922 |
| same 4-KB-per-wave body, lds 16384 (4 waves per CU) | loss | 0.977 |
| same, lds 8192 (8 waves per CU) | loss | 0.9623 |
| same, lds 32768 (2 waves per CU) | parity (CI 0.983..0.992, slightly slower) | 0.9881 |
| hand-written: one wave owns 2 outputs (2 KB), 2 x4 loads in flight, DPP + readlane; grid cdiv(N,512) | loss | 0.9716 |
| earlier block-256 DPP body (4 waves per workgroup) with lds 16384 (16 waves per CU) | parity | 0.9889 |
| probe: x4 load and its wait deleted | diagnostic 61.5 us | None |
| probe: s_endpgm before the wave reduction and store | diagnostic 86.2 us | None |
| probe: s_endpgm first (launch only, 262144 one-wave workgroups) | diagnostic 58.1 us | None |
| earlier sessions (kept, not repeated): coarsen 2/4/8 | parity / loss / loss | 0.9873 |
| earlier: scalar addressing + DPP + readlane rewrite, block 64 and block 256 | parity | 0.9933 |

## Session 2026-11-21 06:51

**Harness verdict:** fallback: the named state 1fd8f8152cfc9ea2 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 0.333) on 50 cases

## mo_reduce_sum, session 2: still at the memory floor (single-touch case)

Baseline `1fd8f8152cfc9ea2` (amdclang, -ffast-math, EPL=4, block 64, 262144 one-wave workgroups at N = 2^26): 84.3 us, headroom 1.06. Every input element is read exactly once (268.4 MB read, 1 MB written), so nothing can read fewer bytes. The 1.5x target is out of reach in principle; the best measured state of two sessions is parity.

### Time split (from the earlier session, not re-measured)
| probe | time |
|---|---|
| full kernel | 84.4 us |
| launch only (262144 one-wave workgroups) | 58.1 us |
| no x4 load / wait | 61.5 us |
| no wave reduction, no store | 86.2 us |

Dispatch and the cold read are overlapping bounds, not additive: cutting the workgroups 8x or 16x (this session) makes the kernel slower, not faster.

### ISA differences tried against amdclang's code
amdclang: 3 scalar kernarg loads, ~17 VALU of 64-bit per-lane addressing (`v_mad_u64_u32`, `v_lshl_add_u64`, `v_cmp_ge_u64`), `s_and_saveexec_b64` tail regions, one `global_load_dwordx4` + `s_waitcnt vmcnt(0)`, `v_pk_add_f32`, 6 `ds_bpermute_b32` each with `s_waitcnt lgkmcnt(0)`, one `global_store_dword`.
The hand-written bodies use scalar `s_lshl_b64` / `s_add_u32` / `s_addc_u32` bases with `global_load_dwordx4 v, v_off, s[4:5]`, a scalar `s_sub_u32` / `s_subb_u32` full/tail branch, 4 `v_add_f32_dpp` + 3 `v_readlane_b32`. This session varied only how the bytes are fetched and how the waves are grouped:

### Opportunities measured this session
| what | expected | measured | verdict |
|---|---|---|---|
| block 512, 8 waves x 1 KB, lds 0 | fewer dispatches (58 us launch-only) | 5cbcb581f60b6bdf 0.963 (0.957..0.967) | loss |
| block 512 + 32 KB LDS (2 wg/CU) | +2 to 3 % (rb_nrm2) | c7a740daffab5df1 0.956 (0.945..0.964) | loss |
| block 512 + 40 KB LDS (1 wg/CU) | +3 to 5 % (rb_dot) | c79df1a08d4f6296 0.965 (0.960..0.972) | loss |
| block 1024, 16 waves x 1 KB | fewer dispatches | 692e439d627d0e4c 0.910 (0.901..0.916) | loss |
| two 512 B `global_load_dwordx2` in flight (rb_scal recipe) | up to +12 % | 1284a13d4c13e20c 0.996 (0.989..1.003) | parity |
| scalar path: 16 `s_load_dwordx16` + 256 scalar-operand `v_add_f32` | unknown (different cache path) | f3c82af1c511ca08 0.224 (0.222..0.225), 377 us | loss |
| 2D grid 1024 x 256 (source level, same body) | dispatch cost | 1cb52bbe1c23dff2 1.002 (0.993..1.005) | parity |

Block-size ranking with the same per-wave body: 64 (1.00) > 256 (0.993) > 512 (0.963) > 1024 (0.910).

### Untested
- A software-pipelined loop over tiles (next tile's load issued before the current tile is reduced): bracketed by coarsen 2/4 (0.987 / 0.946, one load in flight) and the 2- and 4-outputs-per-wave bodies (0.972 / 0.922, all in flight), both losses, so not written.
- Block 128 (2 waves per workgroup): lies between block 64 and block 256, which are 0.7 % apart.

`equivalent(baseline)`: not bit-identical to `ref` (14 of 50 cases identical), all cases within tolerance; the baseline sums in another order under -ffast-math.

### Tried

| what | outcome | speedup |
|---|---|---|
| hand-written scalar-addressing + DPP body at block 512 (8 waves per workgroup, each wave owns one output and 1 KB), grid cdiv(outputs, 8), lds 0 | loss (CI 0.957..0.967, 60 pairs) | 0.9626 |
| same block-512 body with a 32 KB LDS reservation (2 workgroups per CU, the rb_nrm2 optimum) | loss (CI 0.945..0.964) | 0.9557 |
| same block-512 body with a 40 KB LDS reservation (1 workgroup per CU, the rb_dot plateau) | loss (CI 0.960..0.972) | 0.9649 |
| same body at block 1024 (16 waves per workgroup), grid cdiv(outputs, 16), lds 0 | loss (CI 0.901..0.916) | 0.91 |
| rb_scal recipe at block 64: the wave's 1 KB as two global_load_dwordx2 in flight (lane*8, offset 0 and 512), one wait | parity (CI 0.989..1.003) | 0.9957 |
| scalar read path: full tiles read with 16 s_load_dwordx16 (4 in flight per lgkmcnt wait) into s16..s79, 256 serial v_add_f32 with a scalar operand under exec=1; vector path kept for the tail | loss, 377 us (CI 0.222..0.225) | 0.2243 |
| source level: same baseline body on a 2D grid 1024 x cdiv(outputs,1024) (o = blockIdx.y*1024 + blockIdx.x) instead of 262144 workgroups in one dimension | parity (CI 0.993..1.005) | 1.0019 |
| earlier sessions (kept, not repeated): LDS reservations on amdclang's code, 2 and 4 outputs per wave with loads in flight, block-256 DPP body, coarsen 2/4/8, scalar addressing + DPP at block 64 | parity or loss | 1 |
