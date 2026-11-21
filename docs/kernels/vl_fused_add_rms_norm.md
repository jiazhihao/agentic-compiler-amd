# `vl_fused_add_rms_norm`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 08:58

**Harness verdict:** fallback: the named state 126ce7cd54556fa4 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 3.53e-07) on 78 cases

## vl_fused_add_rms_norm: at the memory floor (parity explained)

**Case:** every tensor element is touched exactly once per direction (input read+written, residual read+written, 268.5 MB each way; weight 16 KB is cache-resident). The baseline source already keeps z = input + residual in registers across the reduction, so there is no re-read to remove. Headroom 0.97-0.98: the kernel is slightly faster than the copy model.

### Hot path (bench shape D=4096, block 1024, 16 waves per row)
Entry (3 scalar loads, 64-bit row address math, 3 v_cmp masks) -> `.Lft4`: 2 `global_load_dwordx4` (input, residual), one `s_waitcnt vmcnt(0)`, 2 `v_pk_add`, `global_store_dwordx4` residual, 2 `v_pk_mul` + 3 `v_add` -> `.LBB0_14`: cub shfl reduction (6 `ds_bpermute_b32`, each with `lgkmcnt(0)`), lane-0 `ds_write_b32`, `s_barrier`, wave 0 second level (4 bpermute), thread 0 div + `v_rsq_f32`, `ds_write`, `s_barrier`, `ds_read_b32` -> `.LBB0_29`: weight `global_load_dwordx4`, `vmcnt(0)`, 3 mul, `global_store_dwordx4` input. About 200 executed instructions per wave, 3 vector loads, 2 vector stores, 2 barriers. The strided loops (.LBB0_12/32/36) never run at D <= 4096.

### Time split (probes, us; baseline 100-102)
| variant | time | reading |
|---|---|---|
| full | 99.7-102.7 | |
| no input/residual loads (e8103155) | 51.4 | cold reads ~50 us (268 MB at ~5.4 TB/s) |
| no stores at all (d295bf12) | 95.8 | stores ~4-6 us on top of the reads (they overlap) |
| no input store only (70fd5ec1) | 100.3 | ~0 |
| no barriers (493b90f9) | 105.4 | 0 (noise) |
Launch fixed ~20 us; ALU/LDS/barriers are hidden under the load latency.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| LDS throttle, 1 workgroup/CU (relaunch lds 40960) | <= 3 % (rb_nrm2/rb_dot) | b5dfcfe1 0.997 [0.991,1.007] | parity |
| mask-free scalar fast path (~12 of ~200 instr., loads issued a few instructions earlier) | <= 1 % | 6cbe8de3 1.001 [0.994,1.009] | parity |
| residual store deferred past barriers, adjacent to input store | unknown; reads no longer share the queue with a store | ea277ad9 1.005 [1.000,1.010] | parity |
| 8 waves x 2 KB (source BLK=512,KCH=2) | +-1 % | 957672a1 0.970 [0.965,0.974] | loss |
| coarsen 2/4/8 (earlier) | fewer workgroups | 0.968 / 0.925 / 0.934 | loss |
| one barrier, per-wave second-level reduce (earlier) | barrier time | f008346d 0.999 | parity |
| weight load in flight with the cold loads (earlier) | one latency | 0ea7f29d 1.001 | parity |

### ISA difference of the candidates vs amdclang
No candidate is shipped. The closest (ea277ad9) differs from the baseline by 6 `v_mov_b32` and the position of one `global_store_dwordx4`; 6cbe8de3 adds `s_cmp_eq_u32`/`s_cbranch_scc1` and a 14-instruction duplicate of `.Lft4` without the three `s_*_saveexec`/`s_cbranch_execz` pairs.

### Untested
DPP wave reduction in place of the bpermute tree (the barrier/reduction probe shows 0 us to gain; fi_fused_add_rmsnorm measured it parity); two rows per workgroup (lost on vl_rms_norm and mo_t5_layernorm). Only moving fewer bytes could help and the contract needs all of them.

Shipped state: `baseline` (amdclang's own code; trivially equivalent to itself, within tolerance of `ref` per the battery).

### Tried

| what | outcome | speedup |
|---|---|---|
| LDS reservation 40 KB (one 16-wave workgroup per CU in flight), relaunch only | parity | 0.997 [0.991, 1.007], 120 pairs |
| source geometry BLK=512 KCH=2 (8 waves per row, 2 KB per wave); amdclang's build, source level | loss | 0.970 [0.965, 0.974], 120 pairs |
| mask-free fast path: s_cmp_eq_u32 hidden,0x1000 -> loads issued without the saveexec chain, jump to the reduction | parity | 1.001 [0.994, 1.009], 120 pairs |
| residual store deferred past both barriers, issued next to the input store (z copied to v[28:31]) | parity | 1.005 [1.000, 1.010], 120 pairs |
| earlier session: coarsen 2 / 4 / 8 | loss | 0.968 / 0.925 / 0.934 |
| earlier session: one barrier instead of two (every wave reduces the 16 wave partials itself, rsqrt per wave, no s_variance LDS round trip) | parity | 0.999 |
| earlier session: weight x4 load in flight with the input/residual loads, first wait weakened to vmcnt(1) | parity | 1.001 |
| probes (diagnostic only): no stores 95.8 us; no barriers 105.4 us; no input/residual loads 51.4 us; no input store 100.3 us | diagnostic | n/a |

## Session 2026-11-21 09:01

**Harness verdict:** fallback: the named state 126ce7cd54556fa4 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 3.53e-07) on 78 cases

## vl_fused_add_rms_norm, session 3: at the memory floor (parity explained, three more kinds measured)

**Case:** every element of `input` and `residual` is read once and written once (268.5 MB each way in the model); z = input + residual stays in registers across the reduction, so no re-read exists to remove. Headroom 0.97-0.99 (baseline 100-104 us against a 104.7 us copy-model floor).

### Hot path (unchanged from the earlier analysis)
Entry: 3 scalar loads, 64-bit row address math, 3 `v_cmp` masks -> `.Lft4`: 2 `global_load_dwordx4`, `s_waitcnt vmcnt(0)`, 2 `v_pk_add_f32`, `global_store_dwordx4` (residual), 2 `v_pk_mul_f32` + 3 `v_add_f32` -> `.LBB0_14`: 6 `ds_bpermute_b32` each with `lgkmcnt(0)`, `ds_write_b32`, `s_barrier` -> `.Lft7` (wave 0): `ds_read_b32` + 4 bpermute -> `.Lft8` (thread 0): div + `v_rsq_f32`, `ds_write_b32` -> `s_barrier`, `ds_read_b32` -> `.LBB0_29`: weight `global_load_dwordx4`, `vmcnt(0)`, 3 mul, `global_store_dwordx4` (input). Static mix: 387 instructions, 29 waits (27 wait for everything), 12 LDS reads, 2 barriers; the strided loops never run at D <= 4096.

### Time split (earlier probes, us; not repeated)
full 100-103; no input/residual loads 51; no stores 96; no barriers 105; launch ~20. The cold reads are ~50 us, everything else hides under them.

### Opportunities measured this session
| what | expected | measured | verdict |
|---|---|---|---|
| DPP reduction in place of both bpermute trees (listed untested before) | 0 (barrier/reduction probe showed nothing) | 1ee5395954dca26d 0.981 [0.974, 0.989], 120 pairs | loss |
| `s_setprio 3` after the cold loads' wait | unknown, scheduling | 280b6a3498a9394e 0.994 [0.990, 1.003] | parity |
| residual x4 load before input x4 load | ~0 | d73ebf0ff1e51e72 0.996 [0.993, 1.001] | parity |

Earlier sessions: LDS throttle 0.997, mask-free fast path 1.001, residual store deferred 1.005, 8 waves x 2 KB 0.970, coarsen 0.968/0.925/0.934, one barrier 0.999, weight load in flight 1.001.

### ISA difference of the candidates vs amdclang
Nothing is shipped. 1ee5395954dca26d removes 10 `ds_bpermute_b32`, 10 `s_waitcnt lgkmcnt(0)`, the `v_cmp`/`v_cndmask` lane-count logic and the block-size scalar load, and adds 8 `v_add_f32_dpp`, 4 `v_readlane_b32`, `s_nop` wait states; it is 1.9 % slower. 280b6a3498a9394e adds one `s_setprio`; d73ebf0ff1e51e72 swaps two `global_load_dwordx4`.

### Untested
Two rows per workgroup (lost on vl_rms_norm 0.977 and mo_t5_layernorm 0.953; not repeated here). Sub-1 KB waves (needs more than 1024 threads per row). Only moving fewer bytes could help, and the contract needs all four streams.

Shipped: `baseline`.

### Tried

| what | outcome | speedup |
|---|---|---|
| DPP wave reduction (4 v_add_f32_dpp + 4 v_readlane_b32 + 3 scalar-operand adds) in place of the 6-step ds_bpermute tree, and ds_read + 4 DPP steps in row 0 in place of wave 0's 4-step bpermute second level; fix_hazards; about 80 fewer executed instructions per wave, 10 fewer lgkmcnt waits | loss | 0.981 [0.974, 0.989], 120 pairs |
| s_setprio 3 on the hot path right after the cold loads' s_waitcnt vmcnt(0) (waves holding data get priority to store and finish) | parity | 0.994 [0.990, 1.003], 120 pairs |
| load order swapped on the hot path: residual x4 issued before input x4 | parity | 0.996 [0.993, 1.001], 120 pairs |
| earlier sessions (not repeated): LDS throttle 0.997, mask-free fast path 1.001, residual store deferred 1.005, BLK=512/KCH=2 0.970, coarsen 2/4/8 0.968/0.925/0.934, one barrier 0.999, weight load in flight 1.001 | parity/loss | <= 1.005 |
