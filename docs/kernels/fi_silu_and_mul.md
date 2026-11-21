# `fi_silu_and_mul`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 08:20

**Harness verdict:** win 1.018x (95% CI 1.012 to 1.024) over the strongest amdclang build; outputs within tolerance of the original binary's (largest relative difference 1) on 78 cases

## fi_silu_and_mul: ISA-level analysis

**Case: memory floor, touch-once.** Each element of `input` is read once (268 MB) and each element of `out` written once (134 MB). Baseline 96.6 to 98 us, memory floor 92.2 us, headroom 1.05. The 1.5x target is out of reach; the best verified state is 1.02x to 1.03x.

### Time split (baseline 369f769ddd5ae096, B=4096, D4=2048)

| Phase | How measured | Time |
|---|---|---|
| Launch + division preamble + bounds mask, 131072 one-wave workgroups | probe 8f0f086ee69f38f2 (empty body) | 30.9 us |
| Two `global_load_dwordx4` (x and y streams) | remainder | about 55 us |
| `global_store_dwordx4` | probe 7e14c1a1f6f5108c (no store): 85.6 us | about 11 us |
| silu arithmetic (34 VALU incl. exp2 range handling) | probe 626deb628eef7701: 96.0 us | 0 to 1 us |

Probes are single medians without a CI; the arithmetic figure is inside the noise.

### amdclang's code against the best state (isa_diff baseline -> b64a030cb47939aa)

- Instructions 98 -> 40. SALU 35 -> 15: the unsigned division `blockIdx.x / chunks` (`v_cvt_f32_u32`, `v_rcp_iflag_f32`, `v_readfirstlane_b32`, 20 scalar ops, 2 `s_nop`) is gone because the grid is 2D (s2 = chunk, s3 = token).
- Loads: 2 x `global_load_dwordx4 v, v[addr], off` with per-lane 64-bit addresses (`v_lshlrev_b64`, 3 x `v_lshl_add_u64`) -> 2 x `global_load_dwordx2 v, v8, s[base]` with one `v_lshlrev_b32 v8, 3, v0`. Store likewise `global_store_dwordx2 v8, v[0:1], s[8:9]`.
- Arithmetic: the exp2 range handling (4 `v_cmp_gt_f32`, 8 `v_cndmask_b32`, 4 `v_add_f32`, 4 `v_ldexp_f32`) removed; `v_pk_mul`/`v_pk_add` replaced by plain `v_mul_f32`/`v_add_f32` on 2 elements. Same operation order; bit-identical to the baseline on 78 cases.
- Waits: `lgkmcnt(0)` once (both kernarg loads issued at entry), `vmcnt(1)` before the x arithmetic, `vmcnt(0)` before the y multiply, as amdclang.
- Launch: grid `[cdiv(D4,32), B]` x block 64 (262144 workgroups, 512 B per stream each) against `B*cdiv(D4,64)` x block 64 (131072 workgroups, 1 KB each).

Only the last item carries time; the instruction savings measure nothing (arithmetic probe, H4, H6).

### Opportunities

| What | Expected | Measured | Verdict |
|---|---|---|---|
| 512 B per stream per wave (8 B per lane) | 2 to 3 % (fi_gelu_tanh_and_mul) | b64a030cb47939aa 1.0266 (1.021..1.037, 120 pairs); 1.0191 (1.012..1.026, 240 pairs) | pays |
| Same on a 1D grid with the division preamble | same | 453fd3b9ca7d7aa8 1.0201 (1.013..1.026) | pays, no better |
| 4 waves per workgroup at 512 B per wave (block 256) | up to 10 us of launch | 19b38d4d55e4e83a 1.0117 (1.005..1.019) | parity |
| Two 512 B loads in flight per 1 KB wave + mask-free fast path (rb_scal recipe) | 0 to 10 % | a04010a0d5996acd 1.0071 (0.999..1.018) | parity |
| No bounds mask (v_min_u32 clamp) | 0 | 0ca588471e824eea 1.0252 (1.012..1.030) | parity against H1 |
| Half-filled waves, block 32 x dwordx4 (512 B per wave) | 2 % if bytes per wave alone mattered | 8db12f78882b5f47 1.0055 (0.996..1.018) | parity |
| Fewer VALU (earlier session) | 0 to 1 us | a378a457ab16d83c 1.003 | parity |
| coarsen 2/4/8 on the baseline (earlier session) | launch share | 0.948 / 0.942 / 0.926 | loses |

### Equivalence

`equivalent(b64a030cb47939aa, original=baseline)`: bit-identical, 78/78 cases. Against `ref`: not bit-identical (3/78), max abs 1.0 on `large_exponent`, within tolerance; `equivalent(baseline)` gives exactly the same figures, so the difference is the baseline's `exp2`/`rcp` formulation, not this session's edits.

### Untested

- An amdclang source build of the 512 B geometry (2 floats per thread). Not made here; on fi_gelu_tanh_and_mul it matched the hand-written body (0.998), so the gain reported here should be read as geometry that the harness may credit to amdclang.
- 256 B per wave and 12 B per lane: measured losses on fi_gelu_tanh_and_mul (0.84, 0.94), not repeated.
- Block 128 at 512 B per wave; a flat 1D grid without per-row padding (needs a per-lane division).

### Tried

| what | outcome | speedup |
|---|---|---|
| H1: hand-written, 8 B per lane (dwordx2), 512 B per stream per one-wave workgroup, 2D grid [cdiv(D4,32), B], scalar bases + 32-bit lane offset, no exp2 range handling | win | 1.0266 (1.021..1.037, 120 pairs); 1.0191 (1.012..1.026, 240 pairs) |
| H2: same body on a 1D grid B*cdiv(D4,32) keeping amdclang's scalar division preamble (1D vs 2D grid) | win | 1.0201 (1.013..1.026, 120 pairs) |
| H3: H1 with 4 waves per workgroup (block 256, grid [cdiv(D4,128), B]) | parity | 1.0117 (1.005..1.019, 120 pairs) |
| H4: rb_scal recipe: 1 KB per wave as two 512 B halves, 4 loads in flight, pipelined vmcnt(3)/(2)/(2)/(1), mask-free fast path for full workgroups, masked tail | parity | 1.0071 (0.999..1.018, 120 pairs) |
| H5: H1 without the bounds mask: lane index clamped with v_min_u32 to n-1, no compare/saveexec/branch | win, equal to H1 within noise | 1.0252 (1.012..1.030, 120 pairs) |
| H6: half-filled waves: block 32, 16 B per lane (dwordx4), 512 B per stream per wave | parity | 1.0055 (0.996..1.018, 120 pairs) |
| Probe: all silu arithmetic removed | diagnostic: 96.0 us against 96.6 us | n/a |
| Probe: store removed | diagnostic: 85.6 us | n/a |
| Probe: empty body after the bounds mask (launch + preamble of 131072 workgroups) | diagnostic: 30.9 us | n/a |
| Earlier sessions (not repeated): coarsen 2/4/8 on the baseline; fewer VALU (no exp2 range handling); 2D-grid source | loss, loss, loss, parity, parity | 0.948, 0.942, 0.926, 1.003, 0.993 |

## Session 2026-11-21 08:24

**Harness verdict:** win 1.021x (95% CI 1.018 to 1.026) over the strongest amdclang build; outputs within tolerance of the original binary's (largest relative difference 1) on 78 cases

## fi_silu_and_mul: ISA-level analysis (second session)

**Case: memory floor, touch-once.** `input` is read once (268 MB), `out` written once (134 MB). Baseline 96.2 to 97 us, floor 92.2 us, headroom 1.04 to 1.05. The 1.5x target is out of reach. Best verified state 1.0256x over the baseline; under 1 % over an amdclang build of the same geometry.

### Time split
Not re-measured; the earlier session's probes stand (launch + preamble of 131072 workgroups 30.9 us, loads about 55 us, store about 11 us, arithmetic 0 to 1 us). One new probe: merging the two kernarg scalar loads into one (1b468cdee08d3b13) gave 94.8 us against 95.7 us for its parent, single medians, inside the noise.

### amdclang against the best state
`isa_diff(b5a545ec9c6feb8b -> 100901bab2c367e6)`, i.e. amdclang's own build of the 512 B geometry against the shipped state:
- Instructions 58 -> 39. Gone: the bounds mask (`v_cmp_gt_u32`, `s_and_saveexec_b64`, `s_cbranch_execz`; replaced by one `v_min_u32_e32`), the exp2 range handling (2 `v_cmp_gt_f32`, 4 `v_cndmask_b32`, 2 `v_add_f32`, 2 `v_ldexp_f32`, 2 `s_nop`), the per-lane 64-bit addresses (`v_lshlrev_b64`, 3 `v_lshl_add_u64`; replaced by `v_lshlrev_b32 v8, 3, v0` and scalar bases in `global_load_dwordx2 v, v8, s[base]`).
- `v_pk_mul_f32` / `v_pk_add_f32` -> plain `v_mul_f32` / `v_add_f32` (valu_mul 3 -> 6).
- Waits 4 -> 3 (one `lgkmcnt(0)` instead of two).
- Launch: block 128 on grid [cdiv(D4,64), B] against block 64 on [cdiv(D4,32), B]; both 512 B per stream per wave.

None of these carries measurable time: 1.007x (CI 1.002..1.012, 240 pairs).

### Opportunities
| What | Expected | Measured | Verdict |
|---|---|---|---|
| amdclang source build at 512 B per wave | 2 % (geometry) | b5a545ec9c6feb8b 1.016 (1.009..1.021, 240 pairs) | parity by the rule; the geometry gain belongs to amdclang |
| Hand-written body against that build | 0 to 1 % | 0ca588471e824eea 1.0087 over S1 (1.004..1.014, 240 pairs) | parity |
| Block 128, 2 waves x 512 B | 0 to 1 % of launch | 100901bab2c367e6 1.0256 (1.021..1.030, 240 pairs); 1.0071 over S1 (1.002..1.012) | win against the baseline, parity against S1 |
| Descending address order within a row | unknown | c1b4756209e8aa7e 1.0255 (1.020..1.034, 120 pairs) | equal to ascending |
| 4 B per lane request, two 256 B loads per stream per wave | tests bytes per lane against bytes per wave | 2730141a54e570d9 1.0022 (0.990..1.016, 120 pairs) | parity; loses the 512 B gain |
| One scalar kernarg load instead of two | 0 | probe 94.8 us against 95.7 us | noise; not shippable (reads past the kernarg block) |

### Equivalence
`equivalent(100901bab2c367e6, original=baseline)`: bit-identical, 78/78. Against `ref`: not bit-identical (3/78 cases identical), max abs 1.0 on `large_exponent`, within tolerance; the earlier session found the baseline itself gives the same figures against `ref`, so the difference is the baseline's exp2/rcp formulation.

### Untested
- Block 128 on the amdclang source build (a launch-only change; expected equal to the shipped state).
- Alternating two rows along grid x (4 streams active): not run; the full axis swap lost 0.88 on fi_gelu_tanh_and_mul.
- Anything that moves fewer bytes: none exists for a touch-once elementwise kernel.

### Tried

| what | outcome | speedup |
|---|---|---|
| S1: amdclang source build of the 512 B geometry (2 floats per thread, 2D grid [cdiv(D4,32), B], block 64) | parity by the rule (CI straddles 1.01), 240 pairs; credited to amdclang | 1.016 (1.009..1.021) |
| Earlier hand-written H5 body (0ca588471e824eea) directly against the source build S1 | parity (compare, 240 pairs) | 1.0087 (1.004..1.014) over S1 |
| C3: H5 body with 2 waves per workgroup (block 128, grid [cdiv(D4,64), B]), 512 B per stream per wave | win against the baseline; parity against S1 (1.0071, 1.002..1.012, 240 pairs) | 1.0256 (1.021..1.030, 240 pairs); 1.0308 (1.017..1.039, 120 pairs) |
| C5: H5 with each row walked in descending address order (chunk = last - wg_x) | win against the baseline, equal to H5 (1.0252): address direction does not matter | 1.0255 (1.020..1.034, 120 pairs) |
| C8: 512 B per stream per wave as two lane-contiguous 256 B global_load_dword (4 B per lane request; 4 loads and 2 stores per wave) | parity; loses the 512 B gain | 1.0022 (0.990..1.016, 120 pairs) |
| Probe: one s_load_dwordx8 for all kernargs instead of s_load_dword + s_load_dwordx4 (reads past the 20-byte kernarg block, so diagnostic only) | diagnostic: 94.8 us against 95.7 us for its parent, single medians, inside the noise | n/a |
| Mis-parented probe (block-128 index shift left on a block-64 launch); never timed, discarded | not run | n/a |
