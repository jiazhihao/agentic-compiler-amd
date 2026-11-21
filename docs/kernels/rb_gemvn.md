# `rb_gemvn`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 06:40

**Harness verdict:** fallback: the named state 180346aeb51251ba did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 0.000743) on 78 cases

# rb_gemvn: ISA-level analysis (session 2)

## Verdict
At the memory floor for strided reads. Every element of A is read exactly once (268.5 MB), in 128-byte fragments at a 32 KB stride; the baseline runs at 2.83 TB/s, 0.092-0.095 ms, headroom 1.19 against the contiguous-stream model (4.5 TB/s cold read). No machine-level state beat the baseline: best own state 211aac966291dc33 at 1.0015x (CI 0.992-1.013), parity. `baseline` is shipped. `equivalent` was not run because the shipped state is the baseline itself; the hand-written states sum in another order (4 accumulators per lane, LDS sum of 64 partials) and pass the battery (77/77) within tolerance, not bit-identical by construction.

## Baseline hot loop (.LBB0_15, 41 instructions per iteration, 64 iterations per thread)
- 8 `global_load_dword` of A (one per column, per lane) + 2 `global_load_dwordx4` of x, all issued before a single `s_waitcnt vmcnt(0)`: amdclang already has the whole iteration in flight.
- 13 `v_lshl_add_u64` / `v_mad_u64_u32` for addresses, 1 `v_pk_mul` + 3 `v_pk_fma` + 2 adds, 4 `s_nop`, exec-mask loop control.
- A wave is two 32-row groups (block (32,16)): 16 fragments of 128 B = 2 KB of A in flight per wave and wait.
- End: 1 `ds_write_b32`, 1 barrier, 8 `ds_read2_b32` + 15 adds in 32 lanes, once per workgroup.

## Time split (measured)
- About 20 us launch, about 72-75 us reading A.
- x loads: probe 0c2948648c0685c8 (x replaced by a constant in the 2-step loop) 94.7 us against 95.1 us: 0 us within noise.
- Arithmetic / instruction count: state 211aac966291dc33 runs 20 instructions per 2 KB of A instead of 41 and is at parity: 0 us.
- The LDS reduction runs once per workgroup; a 4x larger one (32 `ds_read2_b32`) in 211aac966291dc33 did not show.
So the whole variable time is the strided loads of A.

## ISA differences, baseline against 211aac966291dc33 (isa_diff)
- Loop: 2 `global_load_dwordx4` (4 rows of one column per lane, 8 columns per load) + 2 `global_load_dword` of x + 8 `v_fmac_f32` + 3 `v_lshl_add_u64` + scalar counter (`s_sub_i32`, `s_cmp_ge_i32`, `s_cbranch_scc1`); no `v_mad_u64_u32`, no `v_pk_*`, no nops, no exec-mask loop control. Baseline: 8 dword + 2 x4 loads, 13 address adds, 5 pk fma/mul, 4 nops.
- Launch: block (64,8) with 8 KB LDS against block (32,16); same 256 workgroups x 8 waves.
- A masked tail loop (.LM, 4 dword loads under row masks) for partial workgroups and columns; a scalar-counted single-step loop (.LB).
- End: 2 `ds_write2_b32`, 32 `ds_read2_b32` against 1 write and 8 reads.

## Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| 16 B per lane (dwordx4), 4x fewer load instructions, 8 steps in flight | up to 1.15x (to the contiguous floor) | bf931b05b552895e 0.899 (0.894-0.906) | loss |
| same, 2 steps in flight (16 fragments per wave, as the baseline) | - | 211aac966291dc33 1.0015 (0.992-1.013) | parity |
| same, 1 / 3 / 4 / 15 steps in flight | - | 1a013d56f0da765f 0.948; 50cf8997987abbcb 0.929; f8b3435a529c20c5 0.913; 8adeb269fe1f8c77 0.883 | loss |
| 256 B fragments, 128 workgroups x 16 waves | fewer, longer fragments | 03b7c88fca27e151 0.932 (0.922-0.941) | loss |
| 16 waves per workgroup at source level (WAV=32) | shorter waves | b603d75d4c36b576 0.893 (0.889-0.906) | loss |
| contiguous column range per wave | TLB / page locality per wave | f1676fee591cd6f5 0.972 (0.960-0.980) | loss |
| unroll_loads 4 / 8 / 16 on the baseline (earlier session) | loads in flight | 0.997 / 0.998 / 0.998 | parity |
| coarsen 2 on the baseline | fewer workgroups | refused (non-uniform branch around the barrier) | untested |
| scalar loads for x | removes 2 loads per iteration | probe 0c2948648c0685c8: 0.4 us of 95 | not worth building |

## Untested
- Fewer than 256 workgroups with 8 waves (a hand-written loop over two row groups per workgroup): coarsen refused; the in-flight sweep suggests the device-wide number of concurrent fragments is what matters, so this would have to keep 16 fragments per wave.
- DPP in place of the LDS sum: the reduction is not visible in the timing.
- Reading fewer bytes is impossible: A is read once.

### Tried

| what | outcome | speedup |
|---|---|---|
| Hand-written body, 16 B per lane: lane = 4 rows of one column (global_load_dwordx4), 8 columns per wave per load, 4 accumulators per lane, block (64,8), grid M/32, x per lane with one dword load, LDS sum at the end; 8 steps (64 fragments, 8 KB) in flight per wait | loss | 0.899 |
| Same layout, 2 steps in flight (16 fragments, 2 KB per wave, the baseline's amount) | parity | 1.0015 |
| Same layout, 1 step in flight (8 fragments) | loss | 0.948 |
| Same layout, 3 steps in flight | loss | 0.929 |
| Same layout, 4 steps in flight | loss | 0.913 |
| Same layout, 15 steps in flight (103 VGPRs) | loss | 0.883 |
| Hand-written, 64 rows per workgroup: 16 lanes x dwordx4 = 256 B fragments, 4 columns per load, block (64,16), grid M/64 (128 workgroups x 16 waves), 2 steps in flight | loss | 0.932 |
| Same body on the baseline as parent (launch bounds 512) with block (64,16) | refused: hipModuleLaunchKernel 719, the parent's descriptor allows 512 threads | None |
| Source variant WAV=32 (block (32,32), 256 workgroups x 16 waves, each wave half as long); amdclang's code, not a baseline candidate | loss | 0.893 |
| Hand-written x4 layout where each wave walks a contiguous range of n/8 columns (successive loads 32 KB apart, inside one 2 MB region for 8 steps) instead of interleaved columns; 2 steps in flight | loss | 0.972 |
| coarsen factor 2 on the baseline | refused: a path reaches the end of the program without passing every s_barrier, through a branch that is not workgroup-uniform | None |
| Probe: x loads removed from the 2-step loop (x = 1.0) | diagnostic: 94.7 us against 95.1 us with the loads, the x loads cost nothing measurable | None |
| unroll_loads 4 / 8 / 16 on the baseline (earlier session, kept in the state list) | parity | 0.998 |

## Session 2026-11-21 06:44

**Harness verdict:** fallback: the named state 180346aeb51251ba did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 0.000743) on 78 cases

# rb_gemvn: ISA-level analysis (session 3)

## Verdict
At the floor for strided reads; `baseline` is shipped (1.000x). A is read exactly once (268.5 MB), so this is the "every element touched once" case, not a re-read case. Baseline: 0.0915-0.0957 ms, 2.8 TB/s, reference headroom 1.19-1.20 against the contiguous-stream model. This session measured five more geometry points, none above parity. `equivalent(baseline)`: within tolerance on 78 cases, not bit-identical with the original binary (29 of 78 identical, largest relative difference 0.000743; -ffast-math and a different summation order).

## Baseline hot loop (.LBB0_15, 41 instructions, unchanged from session 2)
- 8 `global_load_dword` of A + 2 `global_load_dwordx4` of x, all issued before one `s_waitcnt vmcnt(0)`.
- 13 `v_lshl_add_u64` / `v_mad_u64_u32`, 1 `v_pk_mul_f32` + 3 `v_pk_fma_f32` + 2 `v_add_f32`, 4 `s_nop`, exec-mask loop control.
- Block (32,16): a wave is two 32-row groups, so 16 fragments of 128 B (2 KB) in flight per wave and wait; 256 workgroups x 8 waves.

## Time split
Not re-measured this session; session 2's numbers stand: about 20 us launch, about 72-75 us strided loads of A, 0 us for x loads (probe 0c2948648c0685c8), 0 us for arithmetic and instruction count (211aac966291dc33), reduction not visible.

## What this session adds: the geometry map (all 60 pairs, against the baseline)
| workgroups x waves | fragment | in flight per wave | state | speedup (CI) | verdict |
|---|---|---|---|---|---|
| 256 x 8 (baseline) | 128 B | 16 (2 KB) | 180346aeb51251ba | 1.00 | - |
| 256 x 4 | 128 B | 32 (4 KB) | 522f8bdc69f84df7 | 0.996 (0.989-1.000) | parity |
| 128 x 8 | 256 B | 16 (4 KB) | e98059d85cc48077 | 0.962 (0.957-0.968) | loss |
| 512 x 4 | 64 B | 32 (2 KB) | 1aa437e70602347a | 0.822 (0.818-0.832) | loss |
| 512 x 8 | 64 B | 16 (1 KB) | f620bee2adddb7e6 | 0.792 (0.777-0.804) | loss |
| 32 x 16 | 1 KB contiguous (dwordx4, 4 rows per lane) | 4 loads (4 KB) | fc1a42e5ee817f68 | 0.465 (0.462-0.470) | loss |

Reading: the workgroup count must equal the 256 CUs; at that count, waves per workgroup and fragments per wave trade off exactly (8 x 16 = 4 x 32). Fewer workgroups lose even with longer contiguous fragments; more workgroups lose even at the same wave count.

## ISA differences
No own machine-level state is shipped, so there is no isa_diff of a winner. The five states above are amdclang builds of the same loop shape with other constants; fc1a42e5ee817f68 differs in kind: its loop (.LBB0_32, 46 instructions) has 5 `global_load_dwordx4` (4 of A, 1 of x), 6 fma, 3 mul, 4 waits of which one waits for everything, and a 16 KB LDS array.

## Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| Contiguous 1 KB per load, a thread owns 4 consecutive rows | up to 1.19x (the contiguous floor) | fc1a42e5ee817f68 0.465 | loss: 512 waves cannot keep enough in flight |
| Half the waves, twice the loads per wait | 0 to a few % (fewer waves to launch) | 522f8bdc69f84df7 0.996 | parity |
| 256 B fragments at 8 waves | TLB / line locality | e98059d85cc48077 0.962 | loss |
| One-line fragments, 512 workgroups | more concurrency | 0.822 / 0.792 | loss |
| Session 2's list (x4 loads, in-flight depth 1-15, contiguous column range per wave, unroll_loads, x as scalars) | - | best 1.0015 | parity or loss |

## Untested, and why
- Rotating the column start per workgroup (to test whether the device-wide synchronous walk down each column is what the memory system rewards): diagnostic only, could only confirm a loss.
- Fewer launched workgroups with the same per-CU concurrency: `coarsen` is refused on the baseline (non-uniform branch around the barrier).
- Cross-workgroup accumulation (waves reading whole columns contiguously, partial sums merged across workgroups): not expressible, no float atomic and no second pass in one launch.
- DPP in place of the LDS sum: the reduction runs once per workgroup and is not visible in the timing.

### Tried

| what | outcome | speedup |
|---|---|---|
| Source: fully contiguous layout. Thread owns 4 consecutive rows (RPT=4), wave reads 1 KB contiguous of one column per load, 4 columns per iteration, block (64,16), grid M/256 = 32 workgroups x 16 waves (512 waves) | loss | 0.4649 |
| Source like baseline, BXX=32 WAV=8 CPI=16, block (32,8): 256 workgroups x 4 waves, 32 fragments of 128 B in flight per wave (same device-wide bytes in flight as the baseline, half the waves) | parity | 0.996 |
| Source like baseline, BXX=64 WAV=8 CPI=16, block (64,8): 128 workgroups x 8 waves, 256 B contiguous fragments, 16 per iteration | loss | 0.9617 |
| Source like baseline, BXX=16 WAV=32 CPI=4, block (16,32): 512 workgroups x 8 waves, 64 B fragments, 16 per iteration | loss | 0.7917 |
| Source like baseline, BXX=16 WAV=16 CPI=8, block (16,16): 512 workgroups x 4 waves, 64 B fragments, 32 per iteration (2 KB in flight per wave, 2048 waves as the baseline) | loss | 0.8223 |
| equivalent(baseline) against the original binary | within tolerance on 78 cases, not bit-identical (29 of 78 identical; largest relative difference 0.000743, -ffast-math and another summation order) | None |
| New machine-IR edits on the baseline | not built: the earlier session measured instruction count (20 against 41 per 2 KB), x loads, in-flight depth 1 to 15 and the LDS reduction at 0 us or a loss, and this session's geometry sweep produced no better parent | None |
