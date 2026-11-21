# `kda_step`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 09:28

**Harness verdict:** fallback: the named state d8504d6d46b4d97a did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 4.94) on 106 cases

## kda_step: ISA-level analysis (session 3)

**Verdict: at the memory floor, every element touched once.** S (H x DK x DV = 268 MB) is read once and written once; `bench` gives 5.0 TB/s and headroom 1.02 against the copy model (floor 0.1068 ms, measured 0.109 ms). Nothing was a win; `baseline` ships. Only one of the three timed candidates is a machine-level edit: the brief's six machine-level candidates were not reached, and the stop rests on three consecutive ideas of different kinds bringing less than 1 %.

### What the hot path is
Fast path of the baseline (block 256 = 4 waves per head, lane = (row part p of 8, column group cg of 32)):
- `.Lft14` (469 instr): 16 `global_load_dwordx4` (16 rows x 4 columns per lane, 64 VGPRs of S kept), 16 `ds_read2st64_b32` (k, decay), 145 `v_mul`, 78 `v_add`, 80 `v_cndmask` (row validity), 30 waits (13 pipelined vmcnt, 17 lgkmcnt(0)), `ds_write2` of the partial pred.
- `s_barrier`, then `.Lft15` (522 instr): 8 `ds_read2` of partials, 1 x4 load of v, 100 `v_fmac`, 16 `global_store_dwordx4` with no vmcnt wait, 32 LDS reads of k and q, partial out to LDS.
- `s_barrier`, `.Lft16`: 16 LDS reads, one x4 store of o.
- 125 VGPRs, so 4 waves/SIMD (limiter: vgpr). No scratch.

### Time split (probes, diagnostic; baseline 109 us)
| phase | us |
|---|---|
| launch + g/k/q setup loop + barriers + o store (c15ce2e3c39227d5) | 10.5 |
| 16 x4 loads of S, one wait, no arithmetic (4316332f5c5b391a: 93.7) | 83 |
| phase-1 arithmetic and LDS (f6a468a47c659fcf: 94.9) | 1.2 |
| phase 2: delta rule, 16 x4 stores, partial out | 14 |
| of which the two phase barriers (c91d158635ffd42b: 106.5) | <= 2.5 |
| loads-only in <=80 VGPRs (3a1bf5e5a29bee4b: 90.9) | -3 at most from occupancy |

All VALU, LDS and synchronization together are under 5 us: a perfect machine-level rewrite of everything except the memory operations is bounded at about 1.05x.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| all 16 loads in flight before the first wait (amdclang: 10 + 2 + 2 + 2), vmcnt(15..0) | <= 1 us | 9decbb45ae7a8d6b, 0.995 [0.983, 1.000], bit-identical | parity |
| one wave per workgroup, no barriers, in-wave LDS reduction (source) | <= 2.5 us from barriers, unknown from geometry | 20e9b76a6ac2301b, 0.662 [0.658, 0.666] | loss: each load reads 8 fragments of 128 B instead of 2 of 512 B; 36 VGPR spills |
| occupancy 4 -> 8 waves/SIMD via 16 parts x 8 rows, block 512 (source) | <= 3 us | c446eb9304aa0f8d, 0.939 [0.934, 0.946] | loss |
| waits later / weaker (`fix_waits rewrite`) | 0 | unchanged state | already optimal |
| `coarsen` 2 | notes: -2 % to -4 % on this kernel | refused (barrier path analysis) | not measurable |

### isa_diff
There is no best state other than the baseline. 9decbb45ae7a8d6b differs from it only in the position of six `global_load_dwordx4` and three `s_nop 0` in `.Lft14`, in the vmcnt values of the pipelined waits, and in two added waits (`vmcnt(1)`, `vmcnt(0)`) before the last two rows.

### Untested, and why
- A hand-written fast path in <= 80 VGPRs (6 waves/SIMD): the loads-only probe bounds it at 3 %, and the 8 waves/SIMD source build lost, though that build also halves the bytes per wave, so it does not isolate occupancy.
- A select-free fast path for DK % 8 == 0 (removes 160 `v_cndmask`): bounded by the 1.2 us of phase-1 arithmetic plus part of phase 2.
- DPP in place of the LDS partial pools: the reduction is across waves (8 row parts over 4 waves), so the barriers stay; bounded by 2.5 us.

### Verification caveat
The battery shapes (DV in {1, 149, 150, 151, 157}) all take the slow per-column path of the baseline; the fast path is checked only by `equivalent`'s bench-shape case. `equivalent` against `baseline`: 9decbb45ae7a8d6b bit-identical on 106 cases; c446eb9304aa0f8d within tolerance, 105 of 106 bit-identical (the bench shape differs, because the partial sums are grouped differently).

### Tried

| what | outcome | speedup |
|---|---|---|
| machine IR: phase 1 reordered so all 16 global_load_dwordx4 of S are issued before the first wait (amdclang: 10, then 2+2+2 between the arithmetic), waits pipelined vmcnt(15..0), arithmetic order unchanged | parity (bit-identical to baseline on 106 cases) | 0.995 [0.983, 1.000], 60 pairs |
| source: one wave per workgroup (block 64, grid H*cdiv(cdiv(DV,4),8)); a wave owns 8 row parts x 8 column groups, reductions over row parts through LDS inside the wave, no phase barriers. amdclang spilled 36 VGPRs to scratch (outside the fast path's loads) | loss; within tolerance, not bit-identical to ref | 0.662 [0.658, 0.666] |
| source: baseline text with 16 row parts x 8 rows per thread, block 512 (8 waves per workgroup, 64 VGPRs, occupancy 8 waves/SIMD instead of 4) | loss; within tolerance | 0.939 [0.934, 0.946] |
| apply fix_waits rewrite=true on baseline | no change: returned the parent state (amdclang's waits are already as late and as weak as is legal) | not timed |
| apply coarsen factor 2 on baseline | refused: 'a path reaches the end of the program without passing every s_barrier, through a branch that is not workgroup-uniform' | not timed |
| probes re-timed from the earlier session (diagnostic only): no phase 2 94.9 us (f6a468a47c659fcf); 16 loads + one wait, no arithmetic, no phase 2 93.7 us (4316332f5c5b391a); same in <=80 VGPRs 90.9 us (3a1bf5e5a29bee4b); launch + setup + barriers + o store 10.5 us (c15ce2e3c39227d5); phase barriers removed 106.5 us (c91d158635ffd42b) | time split, not results | n/a |
| not attempted: hand rewrite of the fast path to <=80 VGPRs (6 waves/SIMD) and a select-free fast path. Probes bound them at about 3 % and 1 %, and the block-512 build at 8 waves/SIMD lost, but that build also changes bytes per wave, so the occupancy lever alone is unmeasured on a verified state | untested | n/a |

## Session 2026-11-21 09:35

**Harness verdict:** fallback: the named state d8504d6d46b4d97a did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 4.94) on 106 cases

## kda_step: ISA-level analysis (session 4)

**Verdict: at the memory floor, every element touched once.** S (H x DK x DV = 268 MB) is read once and written once by the baseline; `bench` this session gives 5.06 to 5.16 TB/s and headroom 1.01 and 0.99 against the copy model (floor 0.1068 ms, measured 0.105 to 0.108 ms). Nothing was a win; `baseline` ships. One new machine-level candidate was timed; with the earlier session's that makes two machine-level and two source-level candidates on this kernel, not the six machine-level ones the brief asks for.

### Hot path and time split
Unchanged from session 3 (not re-measured): 16 `global_load_dwordx4` of S per lane account for about 83 us of 109 us, launch + setup + barriers + o store 10.5 us, phase 2 with the 16 x4 stores 14 us, all VALU/LDS/synchronization under 5 us.

### New this session
| what | expected | measured | verdict |
|---|---|---|---|
| S loads issued at kernel entry, in flight during the g/k/q setup loop and up to the first barrier | up to one memory round trip per wave out of the setup phase (part of the 10.5 us) | 05b45e2d96e4cff3, 0.995 [0.992, 0.998], 240 pairs, bit-identical on 106 cases | parity |
| same, loads still in flight across the barrier | same | fc617d846f84a001 refused by static_check (33 waitcnt errors on infeasible paths) | not measurable |

### isa_diff baseline -> 05b45e2d96e4cff3
+46 instructions (1402 -> 1448), same 125 VGPRs, SGPRs 56 -> 64, same launch. Added at entry: 25 SALU (the fast-path test repeated), a copy of `.Lft13` (tid / ncg by reciprocal), 31 `v_min_u32` for the row clamp in place of `v_cndmask` on a compare, one branch. Removed from `.Lft14`: the 64-bit address arithmetic (28 `v_mov`, 15 `v_mad_u64_u32` of the high product, 13 `v_cndmask`) and 2 `s_nop`. Waits: `vmcnt(0)` added before the first `s_barrier`, phase-1 waits become vmcnt(15..0). The loop blocks are identical.

### Opportunities, all sessions
| what | measured | verdict |
|---|---|---|
| all 16 loads before the first wait | 9decbb45ae7a8d6b 0.995 [0.983, 1.000] | parity |
| S loads before the setup loop and barrier | 05b45e2d96e4cff3 0.995 [0.992, 0.998] | parity |
| one wave per workgroup (source) | 20e9b76a6ac2301b 0.662 | loss |
| block 512, 8 waves/SIMD (source) | c446eb9304aa0f8d 0.939 | loss |
| fix_waits / coarsen | no change / refused | n/a |

### Untested, and why
- Select-free fast path for dk == 128 (removes 160 `v_cndmask`): needs a guarded copy of `.Lft14` and `.Lft15`; bounded at about 1 us by the probes.
- Fast path in <= 96 or <= 80 VGPRs (5 or 6 waves/SIMD): bounded at about 3 % by the loads-only probe 3a1bf5e5a29bee4b; not written.
- Two heads per workgroup by hand (`coarsen` refuses the barrier structure).
- S loads left in flight across the first barrier: the checker refuses it.

### Verification caveat
The battery shapes all take the baseline's slow per-column path; the fast path is covered only by `equivalent`'s bench-shape case. `equivalent(05b45e2d96e4cff3, baseline)`: bit-identical on 106 cases, bench shape included.

### Tried

| what | outcome | speedup |
|---|---|---|
| machine IR: S loads in flight before the setup barrier. Fast-path test, Sh pointer, row-part/column-group math and the 16 x4 loads duplicated at kernel entry (32-bit row*dv via one v_mad_u64_u32, address built in the load's destination registers, v_min_u32 for the row clamp); setup-loop registers renamed v1..v11 -> v112..v123; `s_waitcnt vmcnt(0) lgkmcnt(0)` before the first s_barrier; phase-1 address math and loads deleted, waits vmcnt(15..0) | parity; bit-identical to baseline on 106 cases (check 105/105) | 0.995 [0.992, 0.998], 240 pairs |
| same edit without the vmcnt(0) before the barrier (S loads still in flight across the barrier, pipelined waits in phase 1) | refused by static_check: 33 waitcnt errors on paths that cannot run together (entry loads + slow path, entry loads + phase 3 with phase 1 skipped) | not timed |
| baseline A/A control | control | 1.001 [0.989, 1.007], 60 pairs |
| from earlier sessions, not repeated: all 16 loads before the first wait (9decbb45ae7a8d6b 0.995 parity), one wave per workgroup source (20e9b76a6ac2301b 0.662 loss), block 512 / 8 waves per SIMD source (c446eb9304aa0f8d 0.939 loss), fix_waits (no change), coarsen 2 (refused) | parity / loss | n/a |
| not attempted: select-free fast path for dk == 128 (needs a guarded copy of .Lft14 and .Lft15, about 1000 instructions, bounded at about 1 us by the probes); fast path in <= 96 or <= 80 VGPRs for 5 or 6 waves per SIMD (bounded at about 3 % by probe 3a1bf5e5a29bee4b); hand coarsening of two heads per workgroup | untested | n/a |
