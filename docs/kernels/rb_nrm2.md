# `rb_nrm2`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 06:21

**Harness verdict:** fallback: the named state aa480cdd05a2fe9f did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 2.38e-07) on 50 cases

## rb_nrm2: at the memory floor (each element read once, headroom 1.08)

### Baseline hot path (amdclang, block 512, 8 waves x 1 KB, loop-free)
133 instructions static; the executed fast path is ~19 scalar/VALU address instructions, **one `global_load_dwordx4` per lane under one `s_waitcnt vmcnt(0)`**, 2 `v_pk_mul_f32` + 3 `v_add_f32`, a 6-step `ds_bpermute_b32` wave reduction (6 `s_waitcnt lgkmcnt(0)`), one `ds_write_b32` per wave, `s_barrier`, 2 `ds_read_b128` + 8 adds + one `global_store_dword` in thread 0. The 4 `global_load_dword` + `vmcnt(0)` blocks are the tail path only.

### Time split (measured, N = 2^26, 85-86 us total)
| phase | how measured | time |
|---|---|---|
| launch + address ALU + reduction + LDS/barrier + store | probe fddc5a7835036e21 (x4 load removed) | 19.0 us |
| the reads (268 MB) | difference | ~66 us (4.05 TB/s) |
| reduction + LDS + barrier + store alone | probe b80db52c25121aa7 (s_endpgm after the squares): 88.4 us | ~0 us (not in the time) |

Copy-model floor: 79.7 us; headroom 1.08. 1.5x is not reachable without reading fewer bytes, and every element must be read once.

### ISA-level difference of the closest candidate (5af7da68be8b650a) to amdclang's code (isa_diff)
block 512 -> 64, lds 0 -> 40960 reserved; `s_barrier` 1 -> 0, LDS reads 8 -> 0, LDS writes 1 -> 0; `global_load_dwordx4` 1 -> 8 in flight per wave with scalar base + 32-bit lane offset (`global_load_dwordx4 v[..], v1, s[16:17]` and `offset:1024`), waits-for-everything 14 -> 2 (pipelined `vmcnt(7)`..`vmcnt(0)`); 31 serial `v_fmac_f32` in place of `v_pk_mul` + adds; 4 `v_add_f32_dpp` + 4 `v_readlane_b32` in place of 6 `ds_bpermute_b32`; scalar 64-bit range test (`s_sub_u32`/`s_subb_u32`/`s_cbranch_scc1`) to a mask-free path, a 32-load masked tail path for the last workgroup (hence 308 static instructions). `equivalent`: within tolerance, not bit-identical (14 of 50 cases identical, max rel err 2.4e-7) because the summation order changes.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| LDS reservation 40 KB on amdclang's code (rb_dot: 1.03-1.05) | up to +5 % | e8e56cdaf9a213ab 0.9656 (0.959..0.974, 120 pairs) | loses here |
| DPP reduce instead of ds_bpermute tree (earlier) | <= 1 us of 19 | 4095dc9e9316be07 0.9965 (0.992..1.001) | parity |
| DPP reduce + LDS 40 KB | +0..5 % | 49bed15b8048cc1e 1.0024 (0.9995..1.011, 120 pairs) | parity |
| one wave per workgroup, 8 x4 loads in flight, no LDS/barrier (rb_scal recipe) | up to 1.07 (headroom) | 60c8966584865361 0.8738 (0.871..0.882) | loses |
| same + LDS 40 KB (1 workgroup per CU) | - | 5af7da68be8b650a 1.0107 (1.0044..1.0132, 240 pairs) | parity |
| same + LDS 32 KB / 21 KB (2 / 3 per CU) | - | 1bf9f0f6f444ded2 0.978, 54428fbeb03c5016 0.924 vs the 40 KB state | loses |
| coarsen 2 on one-wave body, with / without LDS 40 KB | fewer launches | 7ae9da3a207f9a36 0.943; 345ad9aca6aa2683 0.829 | loses |
| coarsen 4 on one-wave body + LDS 40 KB | fewer launches | ae181293df6f8b7f 0.876 | loses |
| coarsen 2/4/8 on amdclang's code (earlier) | - | 0.939 / 0.839 / 0.790 | loses |

### Reading
The time is the read stream. What moves it by more than noise is how many waves are resident per CU and how long each runs: many loads in flight in many concurrent waves is the worst (0.87), throttling to one such wave per CU recovers parity, and making waves run longer (coarsen) loses at every setting. amdclang's geometry (8 short waves each reading 1 KB contiguous with one x4 load) already sits at the optimum of this family.

### Untested and why
- Block 128 / 256 hand-written bodies (4 / 2 KB per wave): rb_dot measured them equal to block 64 and 512 once the reservation is in place (1.003 in compare); source-level 2 KB per wave on this kernel was already slower (93-98 us).
- Block 1024 with x2 loads (512 B per wave): 0.903 on rb_dot.
- Lean block-512 body with scalar bases and a mask-free path: at most ~1 us of the 19 us non-load time; 0.992 on rb_dot.
- Anything that changes which elements a workgroup owns: fixed by the output (one partial sum per workgroup over 4 chunks `inc` apart).

### Tried

| what | outcome | speedup |
|---|---|---|
| LDS reservation 40 KB on amdclang's code (relaunch only, rb_dot recipe) | loss | 0.9656 |
| DPP wave reduce (earlier session's state) + LDS reservation 40 KB | parity | 1.0024 |
| PROBE: fast-path x4 load removed | probe 19.0 us (full kernel 85 us) | None |
| PROBE: s_endpgm after loads+squares (no reduction, LDS, barrier, store) | probe 88.4 us: the reduction is not in the time | None |
| block 64, one wave per workgroup: 8 x4 loads in flight from 4 scalar bases, pipelined vmcnt(7..0), serial v_fmac, DPP reduce, direct store, no LDS/barrier, masked dword slow path for the tail workgroup | loss | 0.8738 |
| same block-64 body + LDS reservation 40 KB (1 workgroup per CU) | parity (1.0061 at 60 pairs; 1.0107, CI 1.0044..1.0132 at 240 pairs) | 1.0107 |
| block-64 body + LDS 32 KB (2 workgroups per CU), compare against the 40 KB state | loss vs 40 KB state: 0.978 (0.974..0.984) | 0.978 |
| block-64 body + LDS 21 KB (3 workgroups per CU), compare against the 40 KB state | loss vs 40 KB state: 0.924 (0.919..0.929) | 0.924 |
| coarsen 2 on the block-64 body, no LDS | loss | 0.8285 |
| coarsen 2 on the block-64 body + LDS 40 KB | loss | 0.9432 |
| coarsen 4 on the block-64 body + LDS 40 KB | loss | 0.8758 |
| earlier sessions (kept, not repeated): DPP reduce in place of ds_bpermute tree 4095dc9e9316be07 0.9965 parity; coarsen 2/4/8 on amdclang's code 0.939 / 0.839 / 0.790 | parity / loss | 0.9965 |
| v_cmpx_gt_u32_e32 s8, v5 to write EXEC directly in the tail path | refused by static_check ('takes 3 operands, got 2'); replaced by v_cmp + s_mov_b64 exec, vcc | None |

## Session 2026-11-21 06:25

**Harness verdict:** win 1.020x (95% CI 1.018 to 1.024) over the strongest amdclang build; outputs within tolerance of the original binary's (largest relative difference 2.38e-07) on 50 cases

## rb_nrm2, session 2: memory floor, +2 % from the launch reservation

**Case:** each element is read exactly once (268 MB), headroom 1.07-1.09 for the baseline. 1.5x is not reachable; the copy model allows at most ~1.07. Measured gain: 1.021-1.027x.

### Time split (from session 1, unchanged; N = 2^26, ~85.5 us)
| phase | time |
|---|---|
| launch + address ALU + reduction + LDS/barrier + store (probe fddc5a7835036e21) | 19 us |
| the reads | ~66 us |
| reduction + LDS + barrier + store alone (probe b80db52c25121aa7) | ~0 us |

The winning state takes ~2 us out of the read phase (85.5 -> 83.5-84.3 us; traffic 3.09 -> 3.2 TB/s overall).

### ISA-level difference to amdclang's code
None: the best state (23605de723d4eace) is the baseline's 133 instructions unchanged (one `global_load_dwordx4` per lane under `s_waitcnt vmcnt(0)`, 2 `v_pk_mul_f32` + 3 `v_add_f32`, 6 `ds_bpermute_b32`, `ds_write_b32`, `s_barrier`, 2 `ds_read_b128`, `global_store_dword`). The only change is `lds: 0 -> 32768` in the launch, which halves the workgroups resident per CU (4 -> 2, i.e. 32 -> 16 waves). `equivalent` against the original binary: within tolerance, not bit-identical (14 of 50 cases identical, max rel 2.4e-7) — that difference is the baseline source's own summation order; against the baseline the outputs are the same code's.

### Opportunities measured this session
| what | expected | measured | verdict |
|---|---|---|---|
| amdclang code + LDS 32 KB (2 workgroups / 16 waves per CU) | unknown (40 KB lost 3.4 %) | 23605de723d4eace 1.0206 (1.018..1.023) and 1.0271 (1.024..1.031), 240 pairs each | **win** |
| amdclang code + LDS 21.8 KB (3 workgroups / 24 waves per CU) | between | 0bc7bbae74207ab1 1.0023 (0.989..1.013) | parity |
| DPP reduce + LDS 32 KB | <= 1 us more | bacb24247474c2bf 1.0196 vs baseline; 1.0038 (1.0002..1.0062) vs the plain 32 KB state | parity on top |
| one-wave body + 40 KB, 32 contiguous bytes per lane | cache-line sharing between the two loads | dac7254f71e2bbb0 1.012 (1.002..1.021) | parity (= parent 1.011) |
| one-wave body, 2 phases of 4 loads, 2 workgroups per CU | 8 KB in flight per CU with shorter waits | 7358f476c2c9bcee 0.996 (0.986..1.000) | parity |
| coarsen 2 + LDS 32 KB | fewer launches | 43fcbadb8cf217f1 0.938 (0.931..0.945) | loses |

### Resident waves per CU, all points now measured (block-512 amdclang code, 1 KB per wave)
| LDS reservation | workgroups / waves per CU | speedup |
|---|---|---|
| 0 | 4 / 32 | 1.000 |
| 21.8 KB | 3 / 24 | 1.002 |
| 32 KB | 2 / 16 | 1.021-1.027 |
| 40 KB | 1 / 8 | 0.966 |

### Reading
The read stream is the time, and the one knob that moves it is how many bytes a CU has in flight: about 8-16 KB is best, 32 KB (the default occupancy) costs 2 %, 8 waves x 1 KB is too few (-3.4 %), 256 KB is far too many (-13 %). The instructions inside the wave (reduction form, lane layout, load phasing) are all parity once the concurrency is set.

### Untested and why
- Waves per CU between the integer points (12, 20): the LDS reservation only gives whole workgroups of 8 waves; a block-256 hand-written body (4 waves) with 16/21 KB reservations would give 12 and 20 waves per CU. Expected at most another 0.5 %.
- Lean block-512 body (scalar bases, mask-free path, reduction prep moved under the load) on top of the 32 KB launch: at most ~1 us of the 19 us non-load time; the DPP variant on top measured +0.4 % (parity).
- Block 1024 with x2 loads (512 B per wave): 0.903 on rb_dot, not repeated.
- Anything that changes which elements a workgroup owns: fixed by the output.

### Tried

| what | outcome | speedup |
|---|---|---|
| amdclang code + LDS reservation 32 KB (2 workgroups = 16 waves per CU), relaunch only | win: 1.0361 (1.027..1.046) at 60 pairs; 1.0206 (1.018..1.023) and 1.0271 (1.024..1.031) at 240 pairs | 1.0206 |
| amdclang code + LDS reservation 21.8 KB (3 workgroups = 24 waves per CU) | parity (0.989..1.013) | 1.0023 |
| DPP wave-reduce state (4095dc9e9316be07) + LDS 32 KB | win vs baseline 1.0196 (1.013..1.027, 60 pairs); compare against the plain 32 KB state 1.0038 (1.0002..1.0062, 240 pairs): parity, the DPP reduce adds nothing | 1.0196 |
| block-64 one-wave body + 40 KB, each lane reads 32 contiguous bytes per chunk (two x4 loads at lane*32 + 0/16) instead of two pieces 1 KB apart | parity (1.002..1.021), same as its parent 5af7da68be8b650a (1.0107) | 1.012 |
| block-64 one-wave body, two phases of 4 x4 loads (4 KB in flight per wave), LDS 32 KB (2 workgroups per CU, 8 KB in flight per CU) | parity (0.986..1.000) | 0.996 |
| coarsen 2 on amdclang's code + LDS 32 KB | loss (0.931..0.945), same as coarsen 2 without the reservation (0.940) | 0.9383 |

## Session 2026-11-21 06:31

**Harness verdict:** win 1.022x (95% CI 1.018 to 1.028) over the strongest amdclang build; outputs within tolerance of the original binary's (largest relative difference 2.38e-07) on 50 cases

## rb_nrm2, session 3: read floor confirmed, 1.024-1.026x

**Case:** every element is read exactly once (268.4 MB); baseline headroom 1.08-1.09, best state 1.05. 1.5x is not reachable; the copy model allows about 1.07.

### Time split (N = 2^26, baseline 86.1-86.9 us this session)
| phase | how measured | time |
|---|---|---|
| launch only, block 512 (262144 waves), lds 0 / 32 KB | probes 698960bf77ba0c83 / 6ec0dbbcd01f983f (s_endpgm first) | 17.4 / 17.3 us |
| launch only, block 256 (131072 waves) / block 64 (32768 waves) | probes 4bec9cdeb00a549b / d845f4db509a5131 | 10.6 / 10.6 us |
| everything but the x4 load (session 1) | fddc5a7835036e21 | 19.0 us |
| the reads | difference | ~66 us |

The split is not additive: block 256 launches 7 us cheaper than block 512 and the full kernels take the same 83.7 us. Launch overlaps the read stream, and the read stream sets the time (3.2 TB/s overall).

### ISA-level difference, best state 3dcf47e375b4f914 against amdclang's code (isa_diff)
- Launch: block 512 -> 256, lds 0 -> 32768 (2 workgroups per CU).
- Loads: one `global_load_dwordx4` per lane under `s_waitcnt vmcnt(0)` -> two `global_load_dwordx4 v[6:9] / v[10:13], v[2:3], off (offset:16)` in flight, `vmcnt(1)` then `vmcnt(0)`; a wave reads its whole 2 KB chunk.
- Squares: 2 `v_pk_mul_f32` + 3 `v_add_f32` -> `v_mul_f32` + 7 `v_fmac_f32` (valu_fma +12 with the 8-element masked tail).
- Wave reduce: 6 `ds_bpermute_b32` + 6 `lgkmcnt(0)` + 4 `v_cndmask` -> 4 `v_add_f32_dpp` + 4 `v_readlane_b32` (7 nop wait states); LDS reads 8 -> 1 (`ds_read_b128` of 4 partial sums), branches 8 -> 3, 133 -> 129 instructions, 9 -> 14 VGPRs.
- `equivalent`: within tolerance, not bit-identical (14 of 50 cases, max rel 2.4e-7); the summation order differs.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| waves per SIMD through VGPR count, 5 / 4 / 3 per SIMD (20 / 16 / 12 waves per CU, the non-integer-workgroup points) | up to +0.5 % | c36496efde5d2c6a 0.9105 (0.906..0.916); 69c30efa98e7e787 0.7695 (0.764..0.775); 7851b8d06b439e5d 0.5873 (0.584..0.590) | loses |
| block 256, 4 waves x 2 KB, 2 loads in flight, lds 32 KB | launch 7 us cheaper | aacdfffa24c1e947 1.0279 (1.021..1.034); 0.9978 (0.995..0.999) vs the 32 KB relaunch of amdclang's code | parity with the earlier best |
| block 256 at 3 / 1 workgroups per CU | sweep | 09f4d8c283f6282e 0.925 (0.921..0.932); d0b0d8089d94d632 0.948 (0.945..0.953) vs 2 per CU | loses |
| DPP reduce on the block-256 body | shorter workgroup tail under a throttled launch | 3dcf47e375b4f914 1.0236 (1.0187..1.0259), 1.0256 (1.0207..1.0295); 1.0014 (0.997..1.006) vs 23605de723d4eace | parity on top |
| staggered loads (1 KB in flight per wave) | 8 KB in flight per CU | dbea8df1a3f326ba 0.957 (0.952..0.961) vs parent | loses |

### Reading
Three structurally different codes (amdclang block 512, hand-written block 256 with and without DPP) meet at 83.4-83.9 us once two workgroups are resident per CU. Fewer waves, cheaper launch and a shorter reduction change nothing; fewer or more resident workgroups, fewer loads in flight per wave and a larger register footprint all lose.

### Untested and why
- Block 128 (2 waves x 4 KB) at 2 workgroups per CU: the block-64 body at 2 per CU was already 0.978 of its 1-per-CU point; expected parity at best.
- Kernarg preload (no `s_load_dword` before the load): not expressible in the session.
- Ending waves 1..3 before the barrier: not safe to verify with a battery (race).
- Anything that changes which elements a workgroup owns: fixed by the output.

### Tried

| what | outcome | speedup |
|---|---|---|
| VGPR-count occupancy throttle on amdclang's code, lds 0: dead v_mov to v95 (96 VGPRs, 5 waves/SIMD = 20 waves/CU) | loss (0.906..0.916, 120 pairs) | 0.9105 |
| same, v127 (128 VGPRs, 4 waves/SIMD = 16 waves/CU) | loss (0.764..0.775, 120 pairs) | 0.7695 |
| same, v167 (168 VGPRs, 3 waves/SIMD = 12 waves/CU) | loss (0.584..0.590, 120 pairs) | 0.5873 |
| hand-written block-256 body: 4 waves, wave j reads its whole 2 KB chunk (two x4 loads in flight, 32 contiguous bytes per lane), 8 serial v_fmac, ds_bpermute reduce, LDS merge of 4; lds 32768 (2 workgroups = 8 waves x 2 KB per CU) | win vs baseline 1.0279 (1.021..1.034, 120 pairs); parity vs the earlier best 23605de723d4eace: 0.9978 (0.995..0.999, 240 pairs) | 1.0279 |
| block-256 body, lds 21840 (3 workgroups = 12 waves x 2 KB per CU), compared with the 32 KB state | loss vs 32 KB state: 0.925 (0.921..0.932) | 0.9249 |
| block-256 body, lds 40960 (1 workgroup = 4 waves x 2 KB per CU), compared with the 32 KB state | loss vs 32 KB state: 0.948 (0.945..0.953) | 0.9478 |
| block-256 body + DPP wave reduce (4 v_add_f32_dpp + 4 v_readlane, exec=1 LDS write) in place of the ds_bpermute tree, lds 32768 | win vs baseline 1.0236 (1.0187..1.0259) and 1.0256 (1.0207..1.0295), 240 pairs each; parity vs 23605de723d4eace: 1.0014 (0.997..1.006, 240 pairs) | 1.0236 |
| block-256 DPP body with the two x4 loads staggered (second issued after the first returns: 1 KB in flight per wave) | loss vs parent: 0.957 (0.952..0.961, 120 pairs) | 0.9567 |
| PROBE: empty kernel (s_endpgm first) at block 512 lds 0 / block 512 lds 32 KB / block 256 lds 32 KB / block 64 lds 40 KB | probe: 17.4 / 17.3 / 10.6 / 10.6 us; the 7 us saved in launch at block 256 does not appear in the full kernel (83.7 us both) | None |
