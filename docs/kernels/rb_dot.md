# `rb_dot`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 06:07

**Harness verdict:** fallback: the named state 7f855c4644f12218 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 0.0041) on 50 cases

## rb_dot: ISA-level analysis

**Case: memory floor, each element touched once.** x and y are read once (537 MB), one float per workgroup is written. Baseline 0.135 ms, 3.9 to 4.0 TB/s, `reference_headroom` 0.97. The 1.5x target is out of reach; nothing measured beat the baseline.

### Time split (measured)

| Phase | How measured | Time |
|---|---|---|
| Launch of 32768 workgroups x 8 waves, DPP reduction, LDS write, barrier, LDS read, store | probe c99af839d0fc1f5c (no loads) | 18.4 us |
| Loads of x and y + 4 fmac, no reduction | probe 1a4d81091ce43a9e | 137.1 us (the full time) |
| Load stream alone | difference | about 117 us, 4.6 TB/s |

The reduction, LDS and barrier are not visible in the time.

### amdclang's code (baseline, 157 instructions, loop-free)

Per wave: `v_mad_i64_i32` + two `v_lshl_add_u64` per-lane 64-bit addresses, a `v_cmp_ge_i64` with `s_and_saveexec_b64` choosing between a full path (two `global_load_dwordx4`, one `s_waitcnt vmcnt(0)`, two `v_pk_mul_f32`, three `v_add_f32`) and a masked tail (four blocks of two `global_load_dword` + wait + `v_fmac`), then a 6-step `ds_bpermute_b32` wave reduction with a `s_waitcnt lgkmcnt(0)` each, `ds_write_b32`, `s_barrier`, two `ds_read_b128` and 8 adds in thread 0, one `global_store_dword`.

### Difference to the hand-written body (isa_diff baseline -> 172e4fb8c0ee2e5a)

Instructions 157 -> 114; branches 10 -> 4; LDS reads 8 -> 2 (the `ds_bpermute` tree replaced by 4 `v_add_f32_dpp` + 3 `v_readlane_b32`); waits 15 -> 8; VALU add/sub 33 -> 15, bit ops 16 -> 4, compares 12 -> 4, selects 4 -> 0; SALU 26 -> 35 (the tile base is computed in scalars and used as `global_load_dwordx4 v, v_off32, s[base]`); nop wait states 1 -> 8 (DPP and readlane hazards). Same launch. Measured 0.9923 (CI 0.989 to 1.000): parity.

### Opportunities

| What | Expected | Measured | Verdict |
|---|---|---|---|
| Fewer instructions, mask-free path, DPP reduction, scalar addressing (block 512) | at most the non-load share, under 2 % | 172e4fb8c0ee2e5a 0.9923 (0.9892..0.9997) | parity |
| Wave-to-stream mapping (adjacent waves on distant streams) | unknown | 8a5b42c9e18c5142 0.9932 (0.9915..0.9965) | parity |
| Block 256, 2 KB per wave, 4 wide loads in flight | fewer waves, loads in flight | 9675fc870722fe93 0.9454 (0.9413..0.9503) | loss |
| Block 128, 4 KB per wave, 8 in flight | same family | 16cc2dac3c06f4f7 0.9347 (0.9305..0.9392) | loss |
| Block 64, one wave per workgroup, 16 in flight, no LDS/barrier (the rb_scal recipe) | 1.12x on rb_scal | 0345179cb0de235b 0.9830 (0.9802..0.9867) | loss |
| Block 64, 4 loads per wait | fewer in flight | 4f848f84d5749de4 0.9758 (0.9729..0.9802) | loss |
| Block 1024, 512 B per wave (amdclang source build) | more, shorter waves | 8f618c10bc3ae347 0.9028 (0.8991..0.9061) | loss |
| coarsen 2 / 4 / 8 (earlier session) | fewer workgroups | 0.971 / 0.818 / 0.875 | loss |
| DPP reduction on amdclang's code (earlier session) | no LDS waits | b459ece43bdb3fbd 0.994 | parity |

All timings 240 pairs against the baseline, reference 133.5 to 138.5 us.

### Equivalence

`equivalent("baseline")`: not bit-identical to `ref` (19 of 50 cases identical), within the manifest tolerance in all cases; max rel err 4.1e-3 on `large_exponent/seed0[N=40000]`. The baseline sums in another order than the shipped source.

### Untested

- More, smaller workgroups: the grid is fixed by the workspace partition (one output per 4 chunks of 2 KB).
- The hand-written body at block 1024 (launch bound of the imported code object is 512).
- Reversed traversal, load order, software prefetch: parity or loss on rb_axpy, not repeated here.

### Tried

| what | outcome | speedup |
|---|---|---|
| Hand-written body at the baseline geometry (block 512, 1 KB per stream per wave): scalar tile base + 32-bit lane offset addressing, scalar full-workgroup test to a mask-free path, 4 v_fmac, DPP wave reduction + 3 v_readlane, scalar wave-0 test; 114 instructions against 157 | parity | 0.9923 |
| Block 256: 4 waves per workgroup, each wave 2 contiguous 1 KB tiles per stream, 4 global_load_dwordx4 in flight with pipelined vmcnt(2)/vmcnt(0) | loss | 0.9454 |
| Wave-to-stream mapping at block 512: chunk = w & 3, half = w >> 2, so adjacent waves read streams 64 MB apart instead of adjacent 1 KB tiles | parity | 0.9932 |
| Source level: block 1024, 16 waves per workgroup, 512 B per stream per wave (2 floats per lane); amdclang build | loss | 0.9028 |
| Block 64: one wave per workgroup, 8 tiles of 1 KB per stream, 16 global_load_dwordx4 in flight with pipelined waits, no LDS, no barrier | loss | 0.983 |
| Block 128: 2 waves per workgroup, each wave 4 tiles (2 chunks), 8 wide loads in flight | loss | 0.9347 |
| Block 64, one 2 KB chunk per wait: 4 wide loads issued, waited, accumulated, then the next chunk (at most 4 in flight) | loss | 0.9758 |
| Probe: no loads (launch + reduction + LDS + barrier + store) | diagnostic, 18.4 us | None |
| Probe: loads + fmac only, s_endpgm before the reduction | diagnostic, 137.1 us | None |
| Earlier session, not repeated: coarsen 2 / 4 / 8 and DPP reduction in place of ds_bpermute on amdclang's code | loss / loss / loss / parity | 0.9707 |

## Session 2026-11-21 06:13

**Harness verdict:** win 1.023x (95% CI 1.020 to 1.027) over the strongest amdclang build; outputs within tolerance of the original binary's (largest relative difference 0.0131) on 50 cases

## rb_dot: ISA-level analysis (session 2)

**Case: memory floor, each element touched once.** x and y are read once (537 MB), one float per workgroup is written. Baseline 0.135 to 0.141 ms, 3.8 to 4.0 TB/s, `reference_headroom` 0.97 to 1.01. The 1.5x target is out of reach. This session found the first verified gain, 1.035 to 1.051, and it comes from the launch, not from the instructions.

### Time split

Not re-measured; the earlier session's probes stand: 18.4 us without loads (launch of 32768 workgroups x 8 waves, reduction, LDS, barrier, store), 137.1 us for loads + 4 fmac without the reduction, so about 117 us is the load stream at 4.6 TB/s. Reduction, LDS and barrier are not visible in the time.

### What changed against amdclang's code (isa_diff baseline -> 6c518e7f4aa338a1)

The body is the earlier session's 172e4fb8c0ee2e5a, unchanged: instructions 157 -> 114; branches 10 -> 4; LDS reads 8 -> 2 (six `ds_bpermute_b32` replaced by 4 `v_add_f32_dpp` + 3 `v_readlane_b32`); waits 15 -> 8; VALU add/sub 33 -> 15, bit ops 16 -> 4, compares 12 -> 4, selects 4 -> 0, `v_pk_mul_f32` 2 -> 0 with `v_fmac_f32` in their place (fma 5 -> 8); SALU 26 -> 35 (scalar tile base, `global_load_dwordx4 v, v_off32, s[base]`); nop wait states 1 -> 8. That body alone is parity (0.992).

The only difference that pays is in the launch: `lds: 40960` per workgroup where the code uses 32 bytes. Same grid `cdiv(N, 2048)`, same block 512.

### Opportunities measured this session

| What | Expected | Measured (state, speedup, CI, pairs) | Verdict |
|---|---|---|---|
| LDS reservation 40 KB, hand-written body | unknown, a throttle on resident workgroups per CU | 6c518e7f4aa338a1: 1.034 (1.022..1.046, 60); 1.051 (1.043..1.056, 240); 1.035 (1.029..1.041, 240); compare vs 172e 1.043 (1.041..1.048, 240) | win |
| LDS 40 KB, amdclang's code | same | b2052d9534a00909: 1.016 (1.011..1.019, 240) | win (small) |
| LDS 45 KB | same | a3ebf008f395e750: 1.036 (1.030..1.041, 240); compare with 40 KB 1.001 | win, equal to 40 KB |
| LDS 32.5 KB | same | 78f5c9ba60be7146: 1.016 (1.0095..1.021, 240) | parity by the rule |
| LDS 26.5 KB | same | 030a76200a67bb42: 0.996 (0.992..1.004, 240) | parity |
| LDS 20 KB | control | b981ff4673ec6316: 1.002 (0.996..1.007, 240) | parity |
| LDS 52.5 KB | same | df5a833ebcfca63a: 0.974 (0.970..0.977, 240) | loss |
| LDS 80 KB | 2 workgroups per CU | 18b744a11d6f855a: 0.868 (0.863..0.870, 240) | loss |
| Block 256 body + 40 KB | was 0.945 | 26e41fb8b266759c: 1.039 (1.029..1.054, 60); compare with block 512 at 40 KB 1.003 (1.000..1.007, 240) | win, equal to block 512 |
| Block 256 body + 20 KB | | 10cb3f283f24ca6a: 0.982 (0.973..0.995, 60) | parity/loss |
| Block 128 body + 40 KB | was 0.935 | a1a1833513eb8b6f: 1.028 (1.017..1.043, 60) | win |
| Block 64 body + 40 KB | was 0.983 | 2799a7ff4e1be2b8: 1.027 (1.016..1.047, 60) | win |
| Block 64 body + 20 KB / 10 KB | | 931bdacfcaa1fe71: 0.991; a714042896174143: 0.939 (60) | parity / loss |
| Occupancy throttle by VGPR count (dead `v_mov_b32 v140, 0`) | fewer waves per SIMD | 675677e2def0444a: 0.950 (0.944..0.965, 60) | loss |
| Reversed traversal (b -> gridDim-1-b) | parity on rb_axpy | 4897b896c87cdcd0: 1.001 (0.993..1.006, 60) | parity |

### Reading of the result

The gain follows the reservation, not the code: every body (block 64, 128, 256, 512) lands at 1.03 to 1.05 with 40 KB, and the block-size losses of the earlier session disappear. 163840 / 40960 = 4 workgroups per CU, i.e. 64 KB of input resident per CU. I have not established the mechanism: 4 workgroups of 8 waves is already the 32-wave limit of a CU for the block-512 body, so the reservation should change nothing there, and 45 KB and 52.5 KB (both 3 per CU on paper) differ by 6 %. The numbers are firm; the explanation "workgroups resident per CU" is an inference that the tools could not confirm (`check` reports `lds_bytes: 32` for all of these states).

The 60-pair entries in the table are triage; only the block-512 states and the two compares are at 240 pairs.

### Equivalence

`equivalent("6c518e7f4aa338a1")`: not bit-identical to `ref` (19 of 50 cases identical), within the manifest tolerance in all 50; max rel err 0.013, max abs err 262144 on `large_exponent/seed0[N=40000]` (another summation order than the shipped source, as for the baseline).

### Untested

- A finer LDS sweep between 34 and 50 KB with compare(); the optimum is somewhere in 40 to 45 KB.
- The 40 KB reservation with coarsen, and with the wave-to-stream remapping.
- A 2D grid (another dispatch order) and kernarg preload: no way found to express them at the machine level.
- Whether the same reservation helps other floor-bound kernels (rb_axpy, rb_scal, rb_nrm2, rb_swap): the obvious next measurement.

### Tried

| what | outcome | speedup |
|---|---|---|
| LDS reservation 40 KB per workgroup on the hand-written block-512 body (relaunch lds=40960) | win: 1.034 (60 pairs), 1.051 and 1.035 (240 pairs); compare against 172e 1.043 (1.041..1.048) | 1.035 |
| LDS reservation 40 KB on amdclang's code unchanged (relaunch of baseline) | win, 240 pairs, CI 1.011..1.019 | 1.0157 |
| LDS reservation 45 KB on the hand-written body | win, 240 pairs, CI 1.030..1.041; compare against the 40 KB state 1.001 (parity) | 1.0356 |
| LDS reservation 32.5 KB on the hand-written body | parity by the rule (CI 1.0095..1.021), 240 pairs | 1.016 |
| LDS reservation 26.5 KB | parity, 240 pairs | 0.9955 |
| LDS reservation 20 KB | parity, 240 pairs | 1.0024 |
| LDS reservation 52.5 KB | loss, 240 pairs, CI 0.970..0.977 | 0.9742 |
| LDS reservation 80 KB (2 workgroups per CU) | loss, 240 pairs, CI 0.863..0.870 | 0.8675 |
| Block 256 body (4 waves, 2 KB per stream per wave, was 0.945) + 40 KB LDS | win at 60 pairs (1.029..1.054); compare against the block-512 40 KB state 1.003 (parity) | 1.0389 |
| Block 256 body + 20 KB LDS | parity/loss, 60 pairs (0.973..0.995) | 0.9824 |
| Block 128 body (2 waves, 4 KB per stream per wave, was 0.935) + 40 KB LDS | win at 60 pairs (1.017..1.043) | 1.0282 |
| Block 64 one-wave body (was 0.983) + 40 KB LDS | win at 60 pairs (1.016..1.047) | 1.0269 |
| Block 64 one-wave body + 20 KB LDS | parity, 60 pairs | 0.9908 |
| Block 64 one-wave body + 10 KB LDS | loss, 60 pairs (0.929..0.961) | 0.9386 |
| Occupancy throttle by registers: v_mov_b32 v140, 0 so a wave needs 144 VGPRs (3 waves per SIMD) | loss, 60 pairs (0.944..0.965) | 0.9497 |
| Reversed traversal: workgroup id b -> gridDim-1-b for reads and the workspace index | parity, 60 pairs (0.993..1.006) | 1.0007 |

## Session 2026-11-21 06:16

**Harness verdict:** win 1.022x (95% CI 1.018 to 1.027) over the strongest amdclang build; outputs within tolerance of the original binary's (largest relative difference 0.0131) on 50 cases

## rb_dot: ISA-level analysis (session 3)

**Case: memory floor, each element touched once.** x and y are read once (537 MB), one float per workgroup is written. Baseline 0.131 to 0.141 ms this session, 3.9 to 4.1 TB/s, `reference_headroom` 0.94 to 1.01. The 1.5x target is out of reach. The best verified state is unchanged from session 2: 6c518e7f4aa338a1, re-measured at 1.0275 (CI 1.0247..1.0314, 240 pairs). Nothing tried on top of it added anything.

### Time split

Not re-measured; session 1's probes stand: 18.4 us without loads (launch of 32768 workgroups x 8 waves, reduction, LDS, barrier, store), 137.1 us for loads + 4 fmac without the reduction, so about 117 us is the load stream at 4.6 TB/s. Arithmetic, reduction, LDS and barrier are not visible in the time.

### amdclang's code against the best state (isa_diff from session 1/2, body unchanged)

Instructions 157 -> 114; branches 10 -> 4; six `ds_bpermute_b32` with a `s_waitcnt lgkmcnt(0)` each replaced by 4 `v_add_f32_dpp` + 3 `v_readlane_b32`; waits 15 -> 8; per-lane 64-bit addressing (`v_mad_i64_i32`, two `v_lshl_add_u64`, `v_cmp_ge_i64` + `s_and_saveexec_b64`) replaced by a scalar tile base, `global_load_dwordx4 v, v_off32, s[base]` and a scalar full-workgroup test; two `v_pk_mul_f32` + adds replaced by 4 `v_fmac_f32`. That body alone is parity (0.992). The part that pays is the launch: `lds: 40960` where the code uses 32 bytes.

### Opportunities measured this session (all on top of the 40 KB state; compare = against 6c518e7f4aa338a1, 120 pairs)

| What | Expected | Measured | Verdict |
|---|---|---|---|
| LDS 36 KB | locate the lower edge | 2dc727e0b75c3c48: compare 0.980 (0.969..0.985) | loss |
| LDS 41.5 KB | optimum in 40..45 | 7c407f29e75f1727: compare 1.001 (0.997..1.005) | parity |
| LDS 48 KB | upper edge | 747a0239167d7b7f: compare 1.002 (1.000..1.005); bench 1.009 (1.006..1.014, 240) | parity |
| Wave-to-stream remap + 40 KB | untested combination | feea7ca19ec05f83: compare 1.004 (0.995..1.011) | parity |
| coarsen 2 + 40 KB | untested combination | 00416048fd491841: compare 0.934 (0.927..0.942) | loss |
| Four `global_load_dwordx2` instead of two x4 | 512 B fragments, 4 in flight | 4c5b6b0c14a27153: compare 0.988 (0.985..0.992) | slower |
| `s_setprio 3` before the loads | scheduling | d711c1963c3b408a: compare 0.9995 (0.996..1.003) | parity |
| Block 256 body + 48 KB | fewer waves at the plateau | 3333386fd0e731fe: compare 1.004 (0.999..1.012); bench 1.013 (1.009..1.018, 240) | parity |

The reservation curve is now: 20 KB 1.00, 26.5 KB 1.00, 32.5 KB 1.016, 36 KB about 2 % under the plateau, 40 to 48 KB plateau (1.02 to 1.05 over baseline depending on the run), 52.5 KB 0.974, 80 KB 0.868.

### Caveat on the size of the win

States that direct compares call equal (40 KB, 48 KB, block 256 at 48 KB) benched 1.0275, 1.009 and 1.013 against the baseline in consecutive 240-pair runs, with the reference time moving between 131 and 141 us. The effect is real (compare against the unreserved body was 1.043 in session 2) but its measured size against the baseline ranges from 1.01 to 1.05; the harness's lower-of-two rule may put it at about 1.02.

### Equivalence

`equivalent("6c518e7f4aa338a1")`: not bit-identical to `ref` (19 of 50 cases identical), within tolerance in all 50; max rel err 0.013, max abs err 262144 on `large_exponent/seed0[N=40000]` (another summation order than the shipped source, as for the baseline).

### Untested

- The mechanism of the reservation gain (no tool shows resident workgroups per CU).
- A finer grid than the workspace partition: impossible without an f32 global atomic.
- 2D grid / kernarg preload: not expressible at the machine level.
- The hand-written body at block 1024 with a reservation (amdclang's block-1024 build was 0.90; low expectation).

### Tried

| what | outcome | speedup |
|---|---|---|
| Re-measure of the recorded best: hand-written block-512 body + 40 KB LDS reservation | win, 240 pairs, CI 1.0247..1.0314 | 1.0275 |
| LDS reservation 36 KB on the same body (finer sweep) | loss against the 40 KB state: compare 0.980 (0.969..0.985, 120 pairs) | 0.9801 |
| LDS reservation 41.5 KB | parity against the 40 KB state: compare 1.001 (0.997..1.005, 120 pairs) | 1.0013 |
| LDS reservation 48 KB | parity against the 40 KB state: compare 1.002 (1.000..1.005, 120 pairs); bench against baseline 1.009 (1.006..1.014, 240 pairs) = parity by the rule | 1.0093 |
| Wave-to-stream remap (chunk = w & 3, half = w >> 2) + 40 KB LDS | parity against the 40 KB state: compare 1.004 (0.995..1.011, 120 pairs) | 1.0039 |
| coarsen factor 2 on the 40 KB state | loss against the 40 KB state: compare 0.934 (0.927..0.942, 120 pairs) | 0.9339 |
| Fast path with four global_load_dwordx2 (512 B per load, x/y interleaved) instead of two x4, 40 KB LDS | slower against the 40 KB state: compare 0.988 (0.985..0.992, 120 pairs) | 0.9879 |
| s_setprio 3 before the loads, 40 KB LDS | parity against the 40 KB state: compare 0.9995 (0.996..1.003, 120 pairs) | 0.9995 |
| Block 256 body (4 waves, 2 KB per stream per wave) + 48 KB LDS | parity: compare against the 40 KB block-512 state 1.004 (0.999..1.012, 120 pairs); bench against baseline 1.013 (1.009..1.018, 240 pairs) = parity by the rule | 1.0133 |
