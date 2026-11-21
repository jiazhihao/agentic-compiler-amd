# `vl_rms_norm`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 08:50

**Harness verdict:** fallback: the named state 5e57ec79776da940 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 3.49e-07) on 78 cases

## vl_rms_norm: ISA-level analysis (B=16384, D4=1024, hidden 4096)

**Case:** single-touch kernel at the memory floor. Reads 268.5 MB cold input once (kept in `v[2:5]` across the reduction, no re-read), writes 268.4 MB; the 16 KB weight row is re-read per workgroup from cache. `headroom` 1.10-1.12 (116-117 us vs 104.7 us floor). 1.5x is out of reach without moving fewer bytes, and there are none to drop.

### Hot path of the baseline (amdclang, restructured source, -ffast-math, block 1024)
At the bench shape the code is loop-free: the five loop blocks (`.LBB0_5/9/21/25`) run only for rows longer than 1024 vectors. Per wave, about 120 executed instructions:
- entry: 3 `s_load_dword*`, `s_waitcnt lgkmcnt(0)`, scalar pointer arithmetic, `v_cmp_gt_i32` mask
- `.Lft0`: one `global_load_dwordx4 v[2:5], v1, s[18:19]` (scalar base + 32-bit lane offset), `s_waitcnt vmcnt(0)`, `v_pk_mul_f32` + `v_pk_fma_f32` + `v_add_f32`
- `.LBB0_12`: 6 `v_add_f32_dpp` (quad_perm x2, row_ror 4/8, row_bcast 15/31), `ds_bpermute_b32`, lane-0 `ds_write_b32`
- `.LBB0_14`: one `s_barrier`, 4 `ds_read_b128`, 7 `v_pk_add_f32`, `v_rcp_iflag_f32`, `v_fma_f32`, `v_rsq_f32` with denormal scaling (2 `v_cndmask`), second `s_load_dwordx4` + `s_load_dword`
- `.Lft7`: `global_load_dwordx4` weight, 4 `v_pk_mul_f32`, `s_waitcnt vmcnt(0)`, `global_store_dwordx4`

amdclang already does here what usually has to be done by hand: DPP wave reduction, one barrier, scalar-base addressing, packed FMA, wide load/store, 1 KB contiguous per wave.

### Time split (probes, baseline 116-117 us)
| phase removed | probe | cost |
|---|---|---|
| output store | 92.3 us (977db53f788520a3) | ~25 us |
| `s_barrier` | 117.5 us (5afb222d77ba330e) | 0 |
| weight load + wait | 117.6 us (4edb2fd20aeb0898) | 0 |
| bpermute + ds_write + barrier + 4 ds_read | 117.4 us (c2b155eb8e37986c) | 0 |
| remainder: launch + cold input read | | ~92 us (model: 20 + 60) |

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| scalar fast path, ~12 instr + 3 mask branches fewer per wave | 0 (probes) | 17e4b5068f46dbb4: 1.0003 [0.996, 1.006], 240 pairs | parity |
| 8 waves/row, 2 KB/wave, 2 loads in flight (source defines) | few % | fe2b0b2c6c39e12c: 1.0085 [0.994, 1.015] | parity |
| 4 waves/row, 4 KB/wave, 4 loads in flight | few % | 4e3920d1ba65bda4: 0.955 [0.944, 0.966] | loss |
| coarsen 2 on the 8-wave build | few % | 46781e01b9d8a93e: 0.984 [0.976, 0.988] | loss |
| coarsen 2/4/8 on baseline (earlier) | few % | 0.9725 / 0.966 / 0.932 | loss |
| unroll_loads 4/8/16 (earlier) | 0, loops not executed | 0.999 / 0.911 / 0.890 | parity / loss |
| weight load in flight with input / before barrier (earlier) | 0 | 0.946 / 0.976 | loss |
| reduction without `ds_bpermute` (earlier) | 0 | 0ec269c97a3e9ea6: 0.999 | parity |

`isa_diff` of the fast-path state against the baseline is one `s_cmp_eq_u32`, one `s_cbranch_scc1`, one `s_branch` and a duplicated load / `v_pk_mul` / `v_pk_fma` / `v_add` block; no best state differs from amdclang's code, because the baseline is shipped.

### Equivalence
`equivalent(17e4b5068f46dbb4)` vs `ref`: within tolerance on 78/78 cases, bit-identical on 8, max rel err 3.5e-7 (the difference is the baseline's -ffast-math reduction order, not the edit; the edit keeps the baseline's operation order). Not run on the baseline itself.

### Untested
- Two rows per workgroup in parallel (block 1024 = 2 x 512): lost on mo_t5_layernorm (0.953) and coarsen 2 on the 8-wave build lost here, so not written.
- 240-pair confirmation of the 8-wave geometry (60-pair 1.0085, CI spans 1.0): at best ~1 %, and a source-level result credited to amdclang.
- The fast path is not covered by the battery (D4 <= 257); only `equivalent`'s bench-shape case exercises it.

### Tried

| what | outcome | speedup |
|---|---|---|
| PROBE: delete the output global_store_dwordx4 (.Lft7[6]) | probe 92.3 us vs 116-117 us: store = ~25 us | None |
| PROBE: delete s_barrier | probe 117.5 us: barrier = 0 | None |
| PROBE: delete the weight global_load_dwordx4 and its wait | probe 117.6 us: cached weight load = 0 | None |
| PROBE: delete ds_bpermute, ds_write, barrier and the 4 ds_read_b128 | probe 117.4 us: reduction + LDS + barrier = 0 | None |
| source geometry BLK=512 KCH=2: 8 waves per row, 2 KB per wave, two x4 loads in flight per lane (amdclang build, same source text) | parity, 60 pairs, CI [0.994, 1.015] | 1.0085 |
| source geometry BLK=256 KCH=4: 4 waves per row, 4 KB per wave, four x4 loads in flight per lane | loss, CI [0.944, 0.966] | 0.9547 |
| machine IR: scalar fast path on the baseline (s_cmp_eq_u32 s24, 0x400 / s_cbranch_scc1 to a mask-free load + sum of squares that rejoins at the reduction with empty loop masks; ~12 executed instructions and 3 exec-mask branches fewer per wave) | parity, 240 pairs, CI [0.996, 1.006]; battery 77/77; equivalent to ref within tolerance (not bit-identical: the baseline itself is -ffast-math) | 1.0003 |
| coarsen factor 2 on the 8-wave build (fe2b0b2c6c39e12c) | loss, CI [0.976, 0.988] | 0.9838 |
| earlier session, not repeated: coarsen 2/4/8 on the baseline build | loss | 0.9725 |
| earlier session, not repeated: unroll_loads 4/8/16 | parity 0.999 / loss 0.911 / loss 0.890 (the loops are not executed at the bench shape) | 0.9991 |
| earlier session, not repeated: weight load issued with the input load, or just before the barrier | loss 0.946 / 0.976 | 0.9464 |
| earlier session, not repeated: wave reduction without ds_bpermute (lane 63 writes the LDS slot) | parity | 0.9988 |

## Session 2026-11-21 08:54

**Harness verdict:** fallback: the named state 5e57ec79776da940 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 3.49e-07) on 78 cases

## vl_rms_norm: ISA-level analysis, session 2 (B=16384, D4=1024, hidden 4096)

**Case:** single-touch kernel at the memory floor. 268.5 MB cold input read once (kept in `v[2:5]` across the reduction, no re-read), 268.4 MB written once; the 16 KB weight row is re-read per workgroup from cache at no measurable cost. `headroom` 1.07-1.12 across this session's timings (112-116 us against a 104.7 us floor). 1.5x is out of reach: there are no bytes to drop and no tensor is touched twice.

### Hot path (unchanged from session 1)
Loop-free at the bench shape, ~120 executed instructions per wave: 3 `s_load_dword*` + `s_waitcnt lgkmcnt(0)`; one `global_load_dwordx4 v[2:5], v1, s[18:19]` + `s_waitcnt vmcnt(0)`; `v_pk_mul_f32` / `v_pk_fma_f32` / `v_add_f32`; 6 `v_add_f32_dpp` + `ds_bpermute_b32` + lane-0 `ds_write_b32`; one `s_barrier`; 4 `ds_read_b128` + 7 `v_pk_add_f32`; `v_rcp_iflag_f32`, `v_fma_f32`, `v_rsq_f32`; weight `global_load_dwordx4`, 4 `v_pk_mul_f32`, `global_store_dwordx4`. `mix`: 303 static instructions, 11 x4 loads and 4 x4 stores of which one load pair and one store execute; the five loop blocks never run at this shape.

### Time split (probes; not additive)
| variant | probe | reading |
|---|---|---|
| full kernel | 112-116 us | |
| no input load (5ac47d5c1e592a6e) | 45.4 us | cold read ~70 us, ~3.8 TB/s |
| no input load, no weight load, no store (64bb46a53b6f6f6d) | 27.9 us | launch of 262144 waves + all ALU/LDS/barrier |
| no store (session 1, 977db53f788520a3) | 92.3 us | store ~17-25 us |
| no barrier / no weight load / no LDS reduction (session 1) | 117.4-117.6 us | 0 |

The read runs at 3.8 TB/s against the 4.5 TB/s of the model: at most ~10 us (9 %) would be available if the read could be brought to the best rate seen on this device, and nothing tried moves it.

### ISA-level difference between amdclang's code and the shipped state
None: the baseline is shipped. `isa_diff` was not needed; the two launch candidates are the baseline's (and the 8-wave build's) code byte for byte with another LDS reservation.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| LDS reservation 40 KB on the baseline: 1 workgroup (16 KB in flight) per CU | +2-5 % (rb_nrm2, rb_dot) | 49766e205243e177: 0.997 [0.993, 1.004], 120 pairs | parity |
| LDS reservation 32 KB on the 8-wave build: 2 workgroups (32 KB) per CU | +2 % | 9113d543a603f893: 1.003 [0.997, 1.006], 120 pairs | parity |
| two rows per workgroup in parallel, 8 waves x 2 KB per row (source) | 0 to -5 % (mo_t5_layernorm 0.953) | 8eb7f0d92b34df0a: 0.977 [0.973, 0.985] | loss |
| session 1: scalar fast path | 0 | 17e4b5068f46dbb4: 1.0003 [0.996, 1.006] | parity |
| session 1: 8 waves/row, 2 KB/wave | few % | fe2b0b2c6c39e12c: 1.0085 [0.994, 1.015] | parity |
| session 1: 4 waves/row, coarsen 2/4/8, unroll_loads, weight in flight, no bpermute | | 0.89-1.00 | parity / loss |

### Equivalence
`equivalent(baseline)` against `ref`: within tolerance on 78/78 cases, bit-identical on 8, max rel err 3.5e-7, worst case `large_exponent/seed0[B=37,D4=250]`. The difference is the -ffast-math reduction order of the baseline build.

### Untested
- Pipelined coarsen (row k+1's input load in flight while row k is reduced and stored): needs a hand-written fast path and an odd-B fallback; plain coarsen 2 (0.9725) and two rows in parallel (0.977) both lost, so it was not written.
- LDS reservations between the integer workgroups-per-CU points: at block 1024 only 1 or 2 workgroups fit a CU, and both are measured.
- The strided loops for rows longer than 4096 floats are run by neither the battery nor the bench shape.

### Tried

| what | outcome | speedup |
|---|---|---|
| PROBE: delete the input global_load_dwordx4 and its wait (.Lft0[0:2]), store kept | probe 45.4 us against 112-116 us: the cold input read is ~70 us (268.5 MB at ~3.8 TB/s) | None |
| PROBE: no input load, no weight load, no store (launch + ALU + LDS + barrier only) | probe 27.9 us: launch of 262144 waves plus all arithmetic; store alone is then ~17.5 us on top of it | None |
| launch: LDS reservation 40960 on the baseline code (1 workgroup = 16 waves = 16 KB in flight per CU instead of 2) | parity, 120 pairs, CI [0.993, 1.004]; battery 77/77 | 0.997 |
| launch: LDS reservation 32768 on the 8-wave / 2 KB-per-wave amdclang build fe2b0b2c6c39e12c (2 workgroups per CU, 32 KB in flight instead of 64 KB) | parity, 120 pairs, CI [0.997, 1.006]; battery 77/77 | 1.0026 |
| source: two rows per 1024-thread workgroup in parallel (8 waves x 2 KB per row, row = 2*blockIdx + tid>>9, grid cdiv(B,2), one barrier per two rows, per-row LDS slots), -ffast-math | loss, 60 pairs, CI [0.973, 0.985]; battery 77/77 | 0.9774 |
| earlier sessions, not repeated: scalar fast path 1.0003; 8 waves/row source geometry 1.0085; 4 waves/row 0.955; coarsen 2/4/8 0.9725/0.966/0.932; coarsen 2 on the 8-wave build 0.984; unroll_loads 4/8/16 0.999/0.911/0.890; weight load in flight 0.946/0.976; reduction without ds_bpermute 0.999 | parity / loss, see docs/kernels/vl_rms_norm.md | 1.0003 |
