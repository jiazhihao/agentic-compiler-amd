# `fi_gelu_tanh_and_mul`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 08:08

**Harness verdict:** baseline: the session's source is a stronger amdclang build (1.022x over the baseline) with no machine-level gain on it: a baseline candidate, not a win

## fi_gelu_tanh_and_mul: ISA-level analysis

**Case: memory floor.** Every element is read once (268.4 MB, two streams x and y that are 4*d bytes apart) and written once (134.2 MB). Baseline 96.5-97.7 us against a floor of 92.2 us: headroom 1.05-1.06. 1.5x is not possible without moving fewer bytes, which an elementwise kernel cannot do.

### What amdclang's code spends instructions on (baseline, loop-free, 227 instructions)
- 2 `global_load_dwordx4` + 1 `global_store_dwordx4` per lane (16 B per lane, 1 KB per stream per wave), per-lane 64-bit addresses (`v_lshl_add_u64`).
- 2 scalar loads with separate `s_waitcnt lgkmcnt(0)`, `vmcnt(1)` before the arithmetic, `vmcnt(0)` before the y multiply.
- 151 VALU for libm `tanhf` inlined four times: each element has a `v_cmp_nlt_f32` + `s_and_saveexec` / `s_xor` / `s_cbranch_execz` split into an exp branch (`v_rndne`, `v_exp_f32`, `v_ldexp_f32`, 2 `v_cndmask`, `v_rcp_f32`, 12 nop wait states in total) and a polynomial branch (4 `v_fmaak`), then `v_bfi_b32` for the sign.
- 53 SALU, mostly the 64-bit `token * d` products computed twice.

### Time split (probes on the hand-written fast path 3699e7b9d2e03c2d, 131072 waves)
| variant | us |
|---|---|
| full | 96.3 |
| dispatch only (fast path = `s_endpgm`) | 30.9 |
| arithmetic + store, loads replaced by constants | 34.6 |
| loads + arithmetic, no store | 85.0 |
| loads + store, 32 gelu instructions removed | 98.0 |

Loads cost about 54 us (268 MB at about 5 TB/s), the store 4 to 11 us, the arithmetic nothing measurable.

### amdclang's code against the hand-written state (isa_diff baseline -> 67706bf328c6b217)
227 -> 98 instructions; branches 5 -> 2; nops 8 -> 0; VALU fma 36 -> 4, mul 36 -> 20, compare 13 -> 1, select 8 -> 0, bit ops 14 -> 2; SALU 53 -> 38; loads 2 x 16 B -> 8 B (`global_load_dwordx2 v, v8, s[base]` with scalar base and `tid << 3` offset); no `s_and_saveexec` on the fast path. None of this is worth time: against amdclang's own build at the same geometry it is 0.998 (CI 0.994..1.003).

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| Mask-free scalar-base fast path, branchless body, same geometry | <= 1 % (arithmetic is free) | 3699e7b9d2e03c2d 1.0051 (0.997..1.012) | parity |
| coarsen 2 on it | few % (mo_glu_fwd) | 13ae3eac0966d9b9 0.9897 (0.979..0.995) | parity / slight loss |
| Swapped grid axes | unknown | 5f03a31af3111802 0.8783 (0.870..0.888) | loss |
| 2 KB per wave, 4 loads in flight | dispatch halves (15 us) | 86983a05cc1045ab 0.9841 (0.974..1.001) | parity |
| 512 B per wave, dwordx2 | unknown (8 B optimum on mo_prelu_bwd) | 67706bf328c6b217 1.0268 (1.021..1.031, 240 pairs) | win vs baseline, parity vs source build |
| 2 x 512 B per stream in one wave (rb_scal recipe) | 1.03-1.12 | a7f7e86903945c90 1.0055 (0.995..1.018) | parity |
| 256 B per wave, dword | unknown | 03a12b019986c1ca 0.8355 (0.830..0.847) | loss |
| coarsen 2 on the 512 B state | few % | 051d1964fb7634ef 1.0047 (0.997..1.013) | parity, loses the gain |
| Source: 2 floats per thread, grid cdiv(D4,32) | same as the machine state | 797081167de59acb 1.0223 (1.015..1.028, 240 pairs), bit-identical | win, credited to amdclang |

### Equivalence
- 797081167de59acb (reported): bit-identical to the original binary on all 78 cases.
- 67706bf328c6b217: not bit-identical (4 of 78 cases identical), within the manifest tolerance, max relative difference 0.498 on `large_exponent`: the original's `0.5 * (1 + tanh z)` cancels for large negative x and `rcp(1 + exp2)` does not.

### Untested
- More than one wave per workgroup at the machine level (block 128 / 256): relaunch fails with launch error 719; amdclang's BLK=256 source build was 0.9835 in an earlier session.
- A bit-identical machine version (amdclang's tanh blocks behind the scalar-base fast path): not built, since instruction count and masks were shown to be free and the source build already has the geometry.
- 12 B per lane (768 B per wave) between the 512 B optimum and 1 KB.

### Tried

| what | outcome | speedup |
|---|---|---|
| Mask-free fast path for full workgroups at the baseline geometry (16 B/lane, 1 KB per stream per wave): one s_load_dwordx4 + s_load_dword, scalar bases + 32-bit lane offset, branchless rcp(1+exp2) body, masked tail | parity | 1.0051 |
| coarsen factor 2 on the fast-path state | parity (CI 0.979..0.995) | 0.9897 |
| Grid axes swapped (token on grid x, chunk on grid y): consecutive workgroups step 131 KB apart | loss | 0.8783 |
| 2 KB per stream per wave, 4 dwordx4 loads in flight (offset:1024), pipelined vmcnt(3/2/2/1), half the waves | parity (CI 0.974..1.001) | 0.9841 |
| 8 B per lane, 512 B per stream per wave (dwordx2), grid cdiv(D4,32), mask-free fast path, branchless body | win vs baseline (240 pairs, CI 1.021..1.031); parity vs amdclang's 2-float source build (0.998); not bit-identical, within tolerance | 1.0268 |
| rb_scal recipe: 1 KB per stream per wave as 2 x 512 B dwordx2 per stream, 4 loads in flight, two stores | parity | 1.0055 |
| 4 B per lane, 256 B per stream per wave (dword), grid cdiv(D4,16) | loss | 0.8355 |
| coarsen factor 2 on the 512 B per wave state | parity (the 512 B gain is lost) | 1.0047 |
| Source level: 2 floats per thread (struct f2), block 64, grid cdiv(D4,32), libm tanhf kept | win (240 pairs, CI 1.015..1.028), bit-identical to the original binary; credited to amdclang | 1.0223 |
| Block 256 (4 waves per workgroup) with the fast-path body via relaunch | refused at launch: hipModuleLaunchKernel 719 (not timed); amdclang's BLK=256 build from an earlier session was 0.9835 | None |
| Probes on the fast-path state (not results): dispatch only 30.9 us, arithmetic + store without loads 34.6 us, loads + arithmetic without store 85.0 us, loads + store without gelu arithmetic 98.0 us, full 96.3 us | diagnostic | None |
| Earlier sessions (kept, not repeated): coarsen 2/4/8 on amdclang's code 0.968/0.948/0.929; branchless body at baseline geometry 1.0004; source BLK=256 0.9835 | loss / parity | None |

## Session 2026-11-21 08:15

**Harness verdict:** fallback: the named state 2565c38d8356bf85 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 0.000388) on 78 cases

## fi_gelu_tanh_and_mul: ISA-level analysis (session on the 8 B/lane baseline)

**Case: memory floor.** Each element is read once (268.4 MB: x and y, 4*d bytes apart in the same row) and written once (134.2 MB). Baseline 94.4-95.4 us against a floor of 92.2 us: `reference_headroom` 1.02-1.03. 1.5x would need fewer bytes, which an elementwise kernel cannot have. No machine-level win was found; `baseline` is shipped.

### What amdclang's code spends instructions on (baseline, loop-free, 132 instructions)
- 2 `global_load_dwordx2` + 1 `global_store_dwordx2` per lane (8 B per lane, 512 B per stream per wave), per-lane 64-bit addresses via `v_lshl_add_u64`.
- 2 scalar loads, each with its own `s_waitcnt lgkmcnt(0)`; the `s_load_dwordx4` of the pointers is issued only after the bounds compare and `s_and_saveexec`. `vmcnt(1)` before the arithmetic, `vmcnt(0)` before the y multiply.
- 77 VALU: libm `tanhf` inlined twice, each with `v_cmp_ge_f32` + `s_and_saveexec` / `s_xor` / `s_cbranch_execz` splitting an exp range (`v_rndne`, `v_exp_f32`, `v_ldexp_f32`, 2 `v_cndmask`, `v_rcp_f32`, 3 nop wait states) from a polynomial range (3 `v_fmaak`), then `v_bfi_b32` for the sign.
- 38 SALU, mostly the 64-bit `token * d` product computed twice.

### Time split
Not re-probed: the previous session's probes (dispatch only 30.9 us, loads about 54 us, store 4-11 us, arithmetic not measurable) were taken at 1 KB per wave and still describe the kernel. This session's timings agree: removing 28 instructions, all branches and all masks changed nothing (1.001).

### amdclang's code against the hand-written body (isa_diff baseline -> 88e1399bae561aae)
132 -> 104 instructions; branches 3 -> 0; SALU 38 -> 18; nop wait states 6 -> 2; waits 4 -> 3 (waits for everything 3 -> 2); VALU select 4 -> 6, min_max 0 -> 1 (`v_min_u32` clamps the lane start in place of the bounds compare + `s_and_saveexec`); loads become `global_load_dwordx2 v, v4, s[base]` with a scalar base and a 32-bit byte offset. Registers 13 -> 35 VGPRs, 10 -> 25 SGPRs (occupancy unaffected). Block 64 -> 128, grid cdiv(D4,32) -> cdiv(D4,64).

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| Mask-free, branch-free body, same geometry | <= 1 % | 90cda7e313ab60af 1.0011 (0.992..1.009, 120 pairs) | parity |
| 12 B per lane (dwordx3, 768 B per wave) | unknown, between the 8 B optimum and 16 B | f2c89a90a71b1f20 0.9351 (0.923..0.941) | loss |
| 2 waves per workgroup (block 128), hand-written body | few % from fewer workgroups | 88e1399bae561aae 1.0062 (1.002..1.013, 240 pairs); 1.0192 at 120 pairs | parity |
| 4 waves per workgroup (block 256), hand-written body | few % | 38c9788c65b7ace6 1.0099 (1.005..1.015, 240 pairs); 1.0165 at 120 pairs | parity |
| 4 waves per workgroup, amdclang's code (source) | few % | 2744980a30ae8dbd 1.0039 (1.000..1.010) | parity |
| 8 waves per workgroup (block 512) | few % | 5823f9c679e27c62 1.0028 (0.997..1.005) | parity |
| 16 waves per workgroup (block 1024) | unknown | afbff8206ade418e 0.9752 (0.965..0.982) | loss |
| coarsen 2 / 4 / 8 on the baseline (earlier) | few % | 0.974 / 0.956 / 0.909 | loss |

### Equivalence
- 88e1399bae561aae against `baseline`: bit-identical on all 78 cases.
- Against `ref` (-O3, no fast-math) it is not bit-identical (23 of 78 cases identical, max abs 0.5, max rel 3.9e-4 on `large_exponent`, within tolerance), and neither is the baseline build itself, with the same numbers: the difference is amdclang's -ffast-math, not the hand-written body.

### Untested
- A direct `compare` of the block-128/256 hand-written states against amdclang's block-256 build: all three are within 1 % of the baseline, so the ranking would not change the verdict.
- Cheaper arithmetic within tolerance (`rcp(1 + exp2)`) at block 128: the earlier session measured arithmetic as free.
- Two tokens per workgroup (block [64,2]) and a flattened 1-D grid: different dispatch orders at the same bytes per wave, not built.

### Tried

| what | outcome | speedup |
|---|---|---|
| Hand-written body at the baseline geometry (8 B/lane, block 64, grid cdiv(D4,32)): no EXEC masks or branches, lane start clamped to d-2 with v_min_u32, scalar bases + 32-bit vector offset, both scalar loads before one lgkmcnt(0), amdclang's tanh computed for both ranges + v_cndmask; bit-identical to baseline | parity (120 pairs, CI 0.992..1.009) | 1.0011 |
| 12 B per lane (global_load_dwordx3 / store_dwordx3, 768 B per stream per wave), grid cdiv(D4,48), last lane overlapped by clamping to d-3 | loss (120 pairs, CI 0.923..0.941) | 0.9351 |
| Source: baseline text with block 256 (4 waves per workgroup), grid cdiv(D4,128), launch_bounds(256) - amdclang's code | parity (120 pairs, CI 1.000..1.010) | 1.0039 |
| Hand-written body at block 256 (4 waves per workgroup), grid cdiv(D4,128) | parity at 240 pairs (CI 1.005..1.015); showed win at 120 pairs (1.0165, CI 1.011..1.023) | 1.0099 |
| Hand-written body at block 128 (2 waves per workgroup), grid cdiv(D4,64) | parity at 240 pairs (CI 1.002..1.013); showed win at 120 pairs (1.0192, CI 1.015..1.025); bit-identical to baseline | 1.0062 |
| Hand-written body at block 512 (8 waves per workgroup), grid cdiv(D4,256) | parity (120 pairs, CI 0.997..1.005) | 1.0028 |
| Hand-written body at block 1024 (16 waves per workgroup), grid cdiv(D4,512) | loss (120 pairs, CI 0.965..0.982) | 0.9752 |
| Block 128 by relaunch of a state descended from the baseline (launch_bounds(64)) | refused at launch: hipModuleLaunchKernel 719; not timed | None |
| Earlier in this session store (kept, not repeated): coarsen 2/4/8 on the baseline | loss (0.974 / 0.956 / 0.909) | 0.9739 |
