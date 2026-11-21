# `fi_fused_add_rmsnorm`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 07:58

**Harness verdict:** fallback: the session named no state faster than the baseline

## fi_fused_add_rmsnorm — ISA-level analysis (session 2026-11-21)

**Case: memory floor, each element touched once.** Bench shape B=8192, d=4096: one workgroup per row, 1024 threads (16 waves), one round. Per lane: `global_load_dwordx4` input + residual (cold), `v_pk_add`, `global_store_dwordx4` residual, `ds_write_b128` x; warp reduction (5 `ds_bpermute_b32`), `s_barrier`, cross-warp reduction in warp 0 (5 more bpermute), `s_barrier`; then IEEE division sequence + `v_rsq_f32`, `global_load_dwordx4` weight (16 KB table, cache-resident), `ds_read_b128` x, 4 `v_pk_mul`/2 `v_pk_add`, `global_store_dwordx4` input. x is already kept in LDS, so the input is not re-read: 268.5 MB read, 268.4 MB written, 5.1-5.4 TB/s, reference headroom 0.94-1.0.

### Mix (baseline, 254 instructions, loop-free at the bench shape)
3 vector loads x4, 2 vector stores x4, 13 LDS reads (10 bpermute), 3 LDS writes, 2 barriers, 21 waits (all full), 68 SALU (mostly the rounds = ceil_div computation and loop control), 121 VALU.

### Time split (probes are unpaired; baseline drifted 98.6-106 us between runs)
| Variant | Time |
|---|---|
| baseline | 98.6-106 us |
| both global stores removed (4167ca3a) | 94.0 us → stores ≈ 5 us |
| input store removed (2f390e3e) | 96.6 us → ≈ 2.5 us each |
| reduction + both barriers removed (ccca7ae2) | 104.4 us → ≈ 0 (inside drift) |
| remainder | ≈ 20 us launch + ≈ 70 us for two cold read streams (268 MB at ~4 TB/s) |

### Opportunities
| What | Expected | Measured | Verdict |
|---|---|---|---|
| vmcnt(0) at second-loop head moved to back edge (weight load not behind the store) | ≤ 2 us | bddaafee 0.996 [0.977, 1.012] | parity |
| launch 512 threads (fi_rmsnorm: 1.05x) | 1.05x | 1886f4b9 0.995 [0.986, 1.005] | parity |
| launch 256 threads | geometry point | 48aca03c 0.886 [0.883, 0.892] | loss |
| rounds<=1 fast path: x in v[24:27], no ds_write/read_b128, weight load in flight with the cold loads | ≤ 2 % | 47604944 0.983 [0.981, 0.987] (240) | loss |
| coarsen 2 on the fast path | 1.015 on baseline earlier | b65a4937 0.970 [0.965, 0.974] (240) | loss |
| residual store deferred after the reduction | unknown | 1c1a5fc7 0.975 [0.972, 0.980] (240) | loss |
| DPP reduction, one barrier (no bpermute tree) | ≈ 0 per probe | 74570e5f 0.978 [0.973, 0.981] (240), equal to its parent | no effect |
| coarsen 2 / 4 / 8 on baseline (earlier session) | — | 1.015 / 0.956 / 0.941 | parity / loss / loss |

### amdclang vs the candidates
The best candidate is amdclang's code itself. The fast-path states differ by: one `global_load_dwordx4` (weight) moved into the first load batch, `ds_write_b128`/`ds_read_b128` replaced by 4 live registers, the second-pass loop (12 `v_mov` zeroing, 2 `s_and_saveexec`, 2 waits) replaced by a 9-instruction masked tail, and in 74570e5f the 10 `ds_bpermute_b32` + 2 `s_barrier` replaced by 8 `v_add_f32_dpp`, 4 `v_readlane_b32`, 1 `ds_write_b32`, 1 `ds_read_b32`, 1 `s_barrier`. None of this is on the critical path: fewer executed instructions and fewer LDS operations bought nothing, and adding the weight load to the cold batch cost about 1.7 %.

### Untested
- unroll_loads on the multi-round relaunch (pass refuses multi-block loops); the geometry itself was parity, so little is expected.
- Two rows per workgroup in parallel: impossible at 1024 threads per row without 2 KB per wave, which lost on mo_t5_layernorm (0.97) and rb_nrm2.
- 1.5x would require moving fewer bytes; there are none to save (no re-read, both outputs are required).

### Tried

| what | outcome | speedup |
|---|---|---|
| Move the vmcnt(0) at the head of the second-pass loop to the back edge, so the weight load is issued while the residual store is outstanding | parity | 0.996 [0.977, 1.012], 60 pairs |
| Relaunch amdclang's code with 512 threads per workgroup (8 waves, 2 rounds at the bench shape); the 1.05x this gave on fi_rmsnorm does not transfer | parity | 0.995 [0.986, 1.005], 60 pairs |
| Relaunch with 256 threads per workgroup (4 waves, 4 rounds) | loss | 0.886 [0.883, 0.892], 60 pairs |
| rounds<=1 fast path: x kept in v[24:27] across the reduction (no ds_write_b128/ds_read_b128), weight load issued together with input/residual loads, straight-line masked tail, fallback to amdclang's loops for rounds>=2; bit-identical arithmetic | loss | 0.983 [0.981, 0.987], 240 pairs (60 pairs had said 1.007 parity) |
| coarsen factor 2 on the fast-path state | loss | 0.970 [0.965, 0.974], 240 pairs |
| Fast path + residual store deferred to the tail (phase 1 only loads; both stores after the reduction) | loss | 0.975 [0.972, 0.980], 240 pairs (60 pairs had said 1.011 [1.002, 1.018]) |
| Fast path + DPP wave reduction, one LDS slot per wave, one barrier, 16-slot read + DPP for the cross-wave sum (replaces 10 ds_bpermute and 2 barriers; sum order differs, within tolerance) | loss | 0.978 [0.973, 0.981], 240 pairs (same as its parent 1c1a5fc7: the reduction rewrite itself is worth ~0) |
| unroll_loads on the 512-thread relaunch (two rounds' loads in flight) | refused: 'no loop can be unrolled: the kernel has no single-block loop' | - |
| fix_waits rewrite=true on baseline | unchanged (nothing to repair, returns the parent) | - |
| Probes (diagnostic, unpaired): both global stores removed 94.0 us; input store removed 96.6 us; reduction+barriers removed (earlier state ccca7ae2) 104.4 us, against a baseline that drifted 98.6-106 us between runs | diagnosis | - |
| Earlier sessions (kept, not repeated): coarsen 2 / 4 / 8 on baseline, -ffast-math source | parity / loss / loss / parity | 1.015 / 0.956 / 0.941 / 1.006 |

## Session 2026-11-21 08:01

**Harness verdict:** fallback: the session named no state faster than the baseline

## fi_fused_add_rmsnorm — session 2026-11-21 (second)

**Case: memory floor, each element touched once.** 268.5 MB read (input + residual, cold) and 268.4 MB written per launch, 5.1-5.2 TB/s, reference headroom 0.94-1.01 across this session's runs. amdclang's code already keeps x in LDS across the reduction (no re-read), moves 16 B per lane and 1 KB contiguous per wave per stream, and is loop-free at the bench shape (rounds = 1).

### Time split (from the previous session's probes, not repeated)
~20 us launch, ~70 us the two cold read streams, ~5 us the two global stores, ~0 for the LDS reduction and barriers. Baseline 98.7-106 us between runs.

### New measurements (all 240 pairs)
| What | Expected | Measured | Verdict |
|---|---|---|---|
| coarsen 2 on baseline (settle 1.015 vs 0.985 at 60 pairs) | <= 1.02 | 1b08b855: 1.006 [1.001, 1.012] | parity |
| coarsen 8 on baseline (60 pairs had said 1.010) | <= 1.02 | 85f14a86: 0.952 [0.949, 0.954] | loss |
| 512 threads, two rounds per iteration, 4 x4 loads in flight (source; the 'untested' item of the previous analysis) | <= 1.05 (fi_rmsnorm geometry) | 6d6e3ad0: 0.961 [0.956, 0.969] | loss |

### amdclang vs candidates
The best state is amdclang's code. 6d6e3ad0 differs by 8 waves instead of 16 per workgroup, two `global_load_dwordx4` pairs issued before one wait (335 instructions against 254, 113 SALU against 68), i.e. 2 KB per wave in two halves: slower, like every 2 KB-per-wave layout measured on this device. Coarsening only adds an outer loop around the same body.

### Together with the previous session
Wait placement, 512/256-thread launches, register fast path without ds_write/read_b128, weight load in the cold batch, deferred residual store, DPP reduction with one barrier, coarsen 2/4/8, -ffast-math, loads in flight on 512 threads: 0.886 to 1.006. Nothing on the critical path is an instruction; it is the two cold read streams.

### Untested
- Nothing that moves fewer bytes exists (both outputs required, inputs read once). 1.5x is out of reach in principle (headroom ~1.0).
- A row split over several workgroups would need each to re-read the row for the sum (more bytes): not tried, expected loss.
