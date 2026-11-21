# `mo_t5_layernorm`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 06:56

**Harness verdict:** fallback: the named state 7d1f15820652e6d8 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 3.43e-07) on 78 cases

## mo_t5_layernorm — ISA-level analysis (session 2)

**Case: memory floor.** Each element of `x` is read once and each element of `y` written once; `weight` (4 KB) is a cache hit. Reference headroom 1.04 (64.9 us against the 62.4 us copy-model floor). 1.5x is not reachable without moving fewer bytes, and the baseline (BLK=256, NC=1, -ffast-math) already removed the only redundant traffic (the second read of `x`, worth 1.74x over `ref`).

### What the hot path executes (bench shape D=1024, block 256, one row per workgroup)
No loop runs: `nfull = 256`, so every lane takes exactly one chunk.
- entry: `s_load_dwordx2` + `s_load_dwordx8` kernargs, one `s_waitcnt lgkmcnt(0)`, scalar 64-bit row offset (`s_mul_i32`/`s_mul_hi_u32`), a 64-bit `v_cmp_gt_u64`.
- `.Lft0`: one `global_load_dwordx4 v[2:5], v6, s[28:29]` (16 B per lane, 1 KB per wave), `s_waitcnt vmcnt(0)`, `v_pk_mul_f32` + `v_pk_fma_f32` + `v_add_f32` (2 `s_nop 0`).
- `.LBB0_2`, `.LBB0_6`: second-chunk and tail tests (two more 64-bit compares, `s_and_saveexec`, branches taken).
- `.LBB0_8` .. `.LBB0_24`: `ds_write_b32`, 9 x (`s_barrier`, `ds_read2*_b32`, `v_add_f32`, `ds_write_b32` under shrinking EXEC), final `ds_read_b32`.
- `.LBB0_24`: `v_rcp_iflag_f32`, `v_fma_f32`, then rsqrt as `v_rsq_f64` + a 7-instruction f64 Newton step, `v_cvt_f32_f64`.
- `.Lft13/.Lft14/.LBB0_29`: `v_pk_mul_f32` x2, weight `global_load_dwordx4` + `s_waitcnt vmcnt(0)`, `v_pk_mul_f32` x2, `global_store_dwordx4`.
Static mix: 273 instructions, 26 waits (all full), 9 barriers, 18 LDS ops, 5 x 16-byte loads, 2 x 16-byte stores.

### Time split (measured)
| part | us | how |
|---|---|---|
| total | 64.9 | bench control |
| y store (134 MB) | ~18.5 | probe 55a408792d2697b6 without the store: 46.4 us |
| launch + x read (134 MB) | ~46 | remainder; ~20 us launch + ~26 us read by the device model |
| 9 barriers / LDS tree sync | ~0.2 | probe 30beb06eafd44227 without barriers: 64.66 us |
| arithmetic, rsqrt, masks | not measurable | every edit that removed some measured parity |

### Opportunities: expected and measured
| opportunity | expected at most | state | speedup (95% CI) | verdict |
|---|---|---|---|---|
| DPP wave reduction, 1 barrier instead of 9 | 0.2 us (0.3 %) | 0ba6afa9cf53efb9 | 0.9991 [0.995, 1.003] | parity |
| weight load in flight across the reduction + `v_rsq_f32` | < 1 % | 2e2648e9a50c563c | 0.989 [0.985, 0.994] | parity / slight loss |
| scalar fast path skipping chunk-2 and tail tests | < 1 % | ac6b217d93d9bbd4 | 1.0012 [0.997, 1.006] | parity |
| `coarsen` 2 / 4 / 8 (serial rows per workgroup) | launch share | 90cc2f10.. / 506ee409.. / 13e037fc.. | 0.961 / 0.914 / 0.917 | loss |
| two rows per workgroup in parallel (8 waves, grid R/2) | workgroup dispatch | 21e0e26b9bd6fafd | 0.953 [0.944, 0.961] | loss |
| `unroll_loads` 4 / 8 / 16 | none (loops not executed) | cee5fd23.. / 319a1129.. / 0407f2e7.. | 0.997 / 1.002 / 0.870 | parity / loss |
| geometry: 1 wave per row, 4 KB per wave (source) | no barriers, 4x fewer waves | 8839f322b6d80640 | 0.883 [0.878, 0.888] | loss |
| geometry: 2 waves per row, 2 KB per wave (source) | | 86611c57cf3d46f5 | 0.968 [0.957, 0.978] | loss |
| geometry: 8 waves per row, 8 B per lane (source) | | 34e3c489d3005d22 | 0.710 [0.705, 0.717] | loss |

### amdclang's code vs the best state
The best state is amdclang's build itself. The machine-level variants differ from it only in instructions that cost nothing here: 9 `s_barrier` + 16 `ds_*` replaced by 4 `v_add_f32_dpp` + 4 `v_readlane_b32` + 1 barrier (0ba6afa9), the f64 `v_rsq_f64` Newton chain replaced by `v_rsq_f32` (2e2648e9), about 15 mask/compare instructions skipped (ac6b217d). The wave's time is one 1 KB load and one 1 KB store; everything between them is hidden behind memory.

### Equivalence
`equivalent(baseline)`: within tolerance on all 78 cases, not bit-identical (12 identical; max rel err 3.4e-7; -ffast-math and chunked summation order).

### Untested
- A non-temporal / differently ordered store: no such instruction is available at this level.
- A hand-written body with x and weight loads issued together and no branches at all: its parts (weight in flight, fast path, DPP) each measured parity, so the combination was not built.
- Geometry between the tested points (block 256 with two rows interleaved per wave, lane groups narrower than a wave): the sweep 512 B / 1 KB / 2 KB / 4 KB per wave is monotone away from 1 KB on both sides.

### Tried

| what | outcome | speedup |
|---|---|---|
| PROBE: y store removed (diagnostic, not a result) | probe 46.4 us vs 64.9 us: the store is ~18.5 us | None |
| PROBE: all 9 s_barrier removed (diagnostic, wrong results) | probe 64.66 us vs 64.9 us: barriers + LDS tree sync cost ~0.2 us | None |
| source geometry: one wave per row, block 64, 4 x4 loads per lane (BLK=64 NC=4) | loss | 0.8832 |
| source geometry: two waves per row, block 128, 2 x4 loads per lane (BLK=128 NC=2) | loss | 0.9683 |
| source geometry: 8 waves per row, block 512, 8 bytes per lane (x2 loads, 512 B per wave) | loss | 0.7104 |
| machine IR: two rows per workgroup in parallel (block 512, grid cdiv(R,2), waves 0-3 row 2g, waves 4-7 row min(2g+1,R-1), per-row LDS slots, R appended kernarg) on the DPP-reduction state | loss | 0.9533 |
| machine IR: scalar fast path, D<=1024 and D%4==0 jumps from the first chunk to the reduction (skips second-chunk loop setup, 64-bit compares, tail test) | parity | 1.0012 |
| same two-rows edit with R read at 0x34 via relaunch args | refused by check (abi: relaunch args did not extend the kernel's argument list) | None |
| earlier session: LDS tree with 9 barriers -> DPP wave reduction, 1 barrier | parity | 0.9991 |
| earlier session: weight load in flight across the reduction + v_rsq_f32 instead of the f64 Newton chain | parity (CI [0.985, 0.994], slightly slower) | 0.989 |
| earlier session: coarsen 2 / 4 / 8 | loss | 0.9607 |
| earlier session: unroll_loads 4 / 8 / 16 (loops not executed at D=1024) | parity, parity, loss (0.87 at 16) | 1.0015 |

## Session 2026-11-21 07:01

**Harness verdict:** fallback: the named state 7d1f15820652e6d8 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 3.43e-07) on 78 cases

## mo_t5_layernorm — ISA-level analysis (session 3)

**Case: memory floor, each element touched once.** x (134 MB) read once, y (134 MB) written once, weight (4 KB) re-read from cache by every wave (134 MB of cache-hit loads, measured free). Reference headroom 1.05-1.08 across this session's benches. 1.5x is out of reach without moving fewer bytes; the baseline already removed the only redundant traffic (second read of x).

### Hot path (unchanged from session 2)
D=1024, block 256: no loop runs. Per wave: one `global_load_dwordx4` (1 KB) + `s_waitcnt vmcnt(0)`, `v_pk_mul`/`v_pk_fma`/`v_add`, LDS tree with 9 `s_barrier`, f64 `v_rsq_f64` Newton chain, weight `global_load_dwordx4` + full wait, 4 `v_pk_mul_f32`, one `global_store_dwordx4`. Static mix: 273 instructions, 26 waits (all full), 9 barriers, 18 LDS ops, 22 branches.

### Time split (us)
| part | us | how |
|---|---|---|
| total | 65-67 | bench controls this session |
| y store | ~18.5 | session 2 probe 55a40879 |
| launch + x read | ~46 | remainder (~20 launch + ~26 read by the device model) |
| weight load (cache hit, 1 KB per wave) | ~0 | probe 3e2fb7db: 65.2 us |
| 9 barriers + LDS tree | ~0.2 | session 2 probe 30beb06e |
| all ALU, branches, masks, waits | ~0 (<0.5 %) | 239a159b: hand-written 63-instruction body at 0.994 |
| an EXEC-empty `global_store_dword` in 3 of 4 waves | +0.9 (1.4 %) | 61efc4b3 vs 239a159b |

### amdclang's code vs the hand-written fast path (239a159b)
Fast path executed per wave: 4 scalar loads in one wait, 10 SALU of dispatch, `global_load_dwordx4 v[2:5], v6, s[28:29]`, `v_pk_mul`/`v_pk_fma`/`v_add`, 4 `v_add_f32_dpp` (+`s_nop 1` each), 4 `v_readlane_b32`, 3 scalar-operand `v_add_f32`, one `ds_write_b32` under EXEC=1, **1** `s_barrier`, 2 `ds_read2_b32`, weight `global_load_dwordx4 v[14:17], v6, s[14:15]`, `v_fma_f32` with literal 1/1024 and eps, `v_rsq_f32`, 8 `v_mul_f32`, `global_store_dwordx4 v6, v[2:5], s[22:23]`. Against amdclang: -8 barriers, -14 LDS ops, -~20 waits, -~18 branches, no 64-bit `v_cmp_*_u64`/`v_lshl_add_u64` address math, no f64 Newton chain (`v_rsq_f64`, 2 `v_mul_f64`, 3 `v_fma_f64`, 2 cvt). None of it is visible in the time.

### Opportunities: expected and measured
| opportunity | expected | state | speedup (95 % CI, 240 pairs) | verdict |
|---|---|---|---|---|
| full hand-written mask-free fast path, weight load in flight with x, unbranched rstd store | <= 1 % (sum of session-2 parities) | 4a2e214686bf85da | 0.982 [0.977, 0.989] | loss |
| same, weight load after the barrier | isolates weight position | 61efc4b353548285 | 0.980 [0.975, 0.982] | loss (position irrelevant) |
| same, rstd store branched over when EXEC empty | isolates the empty-EXEC store | 239a159b01db0561 | 0.994 [0.990, 0.998] | parity |
| weight load removed (probe) | bound on weight cost | 3e2fb7db7ada044a | 65.2 us vs 65 us | ~0 |

Session 2 (not repeated): DPP reduce 0.999, weight in flight + rsq_f32 0.989, scalar fast path 1.001, coarsen 2/4/8 0.96/0.91/0.92, two rows per workgroup 0.953, unroll_loads 0.997/1.002/0.870, source geometries 4 KB / 2 KB / 512 B per wave 0.883 / 0.968 / 0.710.

### Equivalence
`equivalent(61efc4b3)` (fast path, bench shape included): within tolerance on 78 cases, 12 bit-identical, max rel 3.4e-7; the baseline is the same class (-ffast-math, chunked summation order).

### Untested, and why
- Four rows per 1024-thread workgroup: two rows already lost 0.953 and coarsen is monotone down.
- A non-temporal store or any store-side change: no such instruction at this level; the store is ~18.5 us at the device's write rate.
- Nothing remains at the machine level that the hand-written body did not already remove; a further gain needs fewer bytes (for example a fused consumer of y), which is outside this kernel's contract.

### Tried

| what | outcome | speedup |
|---|---|---|
| PROBE: weight load skipped (branch as mode 4), wrong results, diagnostic only | probe 65.2 us vs ~65 us baseline: the 1 KB cache-hit weight load per wave costs nothing measurable | None |
| hand-written mask-free fast path for D==1024/mode!=4/rstd!=null (scalar test at entry, fallback to amdclang's code): x and weight loads issued together, vmcnt(1), DPP wave reduce + 4 readlanes, 1 LDS slot per wave, 1 barrier, mean by literal 1/1024, v_rsq_f32, 8 v_mul_f32, scalar-base store, rstd store last under EXEC = (lid==0) without a branch | loss, 240 pairs, CI [0.977, 0.989] | 0.9817 |
| same fast path, weight load issued after the barrier (amdclang's order), vmcnt(0) | loss, 240 pairs, CI [0.975, 0.982]: the weight load position is not the cause | 0.98 |
| same fast path, rstd store moved before the y store and branched over with s_cbranch_execz when EXEC is empty (waves 1-3) | parity, 240 pairs, CI [0.990, 0.998]; +1.4 % over 61efc4b3: the empty-EXEC global_store_dword was the loss | 0.9942 |
