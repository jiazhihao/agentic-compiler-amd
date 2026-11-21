# `fi_merge_state`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 08:30

**Harness verdict:** fallback: the named state 912225486e161830 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 0.852) on 78 cases

## fi_merge_state: ISA-level analysis

**Kind:** loop-free, touch-once elementwise merge (2 row streams read, 1 written, plus 2 scalars per row in and 1 out). Bench shape P=8192, H=32: 270.5 MB read, 135.3 MB written. Baseline headroom 1.08..1.11 against the copy model (memory floor 92.8 us): **at the memory floor; 1.5x is out of reach in principle** (the floor allows about 1.1x). Each element is touched exactly once, nothing is re-read.

### amdclang's code (baseline, 74 instructions, block 64, 131072 workgroups)
One wave = two rows, 32 lanes each, 16 B per lane (`global_load_dwordx4` x2, `global_store_dwordx4`), i.e. 1 KB per stream per wave. Per lane: `v_cmp_gt_u32` + `s_and_saveexec_b64` bounds mask, 7 `v_lshl_add_u64` / 2 `v_lshlrev_b64` / `v_mul_lo_u32` of 64-bit address arithmetic, two `global_load_dword` of s_a[row], s_b[row] (the same address in 32 lanes), the scale math (v_max, v_pk_add, 2 v_exp + range handling with v_cmp/v_cndmask/v_ldexp, v_rcp, 2 v_mul, 2 v_cndmask), 2 `v_pk_mul` + 2 `v_pk_fma`, store, then a masked `v_log` + `global_store_dword` for tx == 0. Waits are already as late and weak as legal (vmcnt(2) for the scalars, vmcnt(1), vmcnt(0)); `fix_waits rewrite` changes nothing.

### Time split (probes, us)
| part | us |
|---|---|
| launch + empty waves (131072 workgroups) | 31.2 |
| v_a, v_b row loads | ~57 |
| v_merged store | ~11..12 (90.4 without) |
| s_a/s_b loads + all scale arithmetic | ~3 (98.9 without) |
| total | 101..103 |

### Best state 912225486e161830 (67 instructions, block 64, grid P*H = 262144)
`isa_diff(baseline, best)`: vector loads 2x16 B + 2x4 B -> 2x8 B; store 16 B -> 8 B; scalar loads +3 x 4 B (head_dim, s_a[row], s_b[row]); SALU +13 (row byte offsets and the three 64-bit bases by `s_mul_i32`, `s_lshl_b64`, `s_add_u32`/`s_addc_u32`); VALU add/sub -8, bit ops -4, compares -2 (no 64-bit per-lane addressing, no bounds compare); pk_mul/pk_fma 2+2 -> 1+1; waits 6 -> 4; branches 2 -> 1. The instructions that matter: `global_load_dwordx2 v[4:5], v8, s[4:5]` / `v[6:7], v8, s[8:9]` with v8 = tid << 3 and `global_store_dwordx2 v8, v[4:5], s[16:17]`: one row = one wave = 512 B contiguous per stream, exact grid, no EXEC mask. The scale math is amdclang's sequence on values moved from SGPRs (`v_mov_b32 v12, s24`), so the output is bit-identical to the baseline (78/78 cases). s_merged is written by lane 0 after `s_mov_b64 exec, 1`.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| 512 B per stream per wave (dwordx2 x 64 lanes), exact grid, scalar addressing | 2..3 % (silu/gelu kb) | 912225486e161830: 1.039 (1.035..1.044, 240 pairs) | pays |
| same body, 2 waves per workgroup | <= launch share | 744c49e670e2b8b3: 1.028 (1.023..1.031) | pays, not better |
| same body, 4 waves per workgroup | <= launch share | c7c98abb4218e736: 1.030 (1.025..1.037) | pays, not better |
| row loads issued before scalar loads | < 1 % | d9194c01399ea06c: 1.028 (1.021..1.034) | no gain over parent |
| coarsen 2 on best | launch share | 667139cf7cf3bdd9: 0.971 (0.963..0.977) | loses |
| amdclang body, block 128 / 256 | launch share | d2d97f12f13a6e7d 0.999; 2e73d186c5c6dce5 0.990 | parity |
| fix_waits rewrite on baseline | 0 | unchanged code | nothing to do |
| (earlier) coarsen 2/4/8 on baseline | | 0.978 / 0.950 / 0.955 | parity / loss |
| (earlier) scalar s loads at amdclang geometry; bare v_exp | <= 3 us | 0.999; 0.993 | parity |

### Untested
Several loads in flight per wave (2 rows per wave, 4 loads before the first wait) was not timed here: it measured parity on fi_silu_and_mul and a loss on rb_axpy for the same kernel class, and coarsen 2 lost on this body. A source-level build of the same geometry (2 floats per thread, grid P*H) was not made; on fi_silu_and_mul the source build got most of the gain (1.016 against 1.025 hand-written), so part of this 1.039 is probably reachable by amdclang. 4 B per lane was not tried (loss on rb_axpy, parity on silu).

### Tried

| what | outcome | speedup |
|---|---|---|
| Hand-written: one wave per row, 8 B per lane x 64 lanes (dwordx2), grid P*H exact (no bounds mask), scalar bases + 32-bit vector offset, s_a/s_b by s_load_dword, same FP order | win | 1.0387 (CI 1.0348..1.0443, 240 pairs); 1.0365 (1.0291..1.0465, 120 pairs) |
| Same body, block 128: two rows (waves) per workgroup, row = wg*2 + wave via v_readfirstlane, scalar bounds branch, grid cdiv(P*H,2) | win | 1.0275 (1.0226..1.0306, 240 pairs); 1.0324 (120 pairs) |
| Same body, block 256: four rows per workgroup, grid cdiv(P*H,4) | win | 1.0304 (1.0248..1.0374, 120 pairs) |
| Best body with the v_a/v_b row loads issued before the s_a/s_b scalar loads | win, not better than parent | 1.0284 (1.0207..1.0342, 240 pairs) |
| coarsen factor 2 on the best body (one wave runs two rows in sequence) | loss | 0.9707 (0.9634..0.9768, 120 pairs) |
| amdclang body at block 128 (shift in v_lshl_add_u32 changed, relaunch) | parity | 0.9986 (0.9915..1.0048, 120 pairs) |
| amdclang body at block 256 | parity | 0.9902 (0.9835..1.0012, 120 pairs) |
| fix_waits rewrite=true on the baseline | nothing to change (waits already latest/weakest); not timed | n/a |
| First hand-written attempt: half a row per wave with dwordx2 (wrong sizing: 64 lanes x 8 B is a whole 128-float row) | battery failed (v_merged 9391 mismatches); not timed | n/a |
| Probes on the baseline: empty body / no v_merged store / no s loads and scale arithmetic | diagnostic: 31.2 us / 90.4 us / 98.9 us against 101..103 us | n/a |
| Earlier sessions (kept, not repeated): coarsen 2/4/8 on the baseline; scalar s_a/s_b loads at amdclang's geometry; bare v_exp_f32 without range handling | parity / loss / loss / parity / parity | 0.978 / 0.950 / 0.955 / 0.999 / 0.993 |

## Session 2026-11-21 08:37

**Harness verdict:** fallback: the named state 12d82a7b250e6e7b did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 0.852) on 78 cases

## fi_merge_state: ISA-level analysis (session 2, 2026-11-21)

**Case:** touch-once, loop-free elementwise row merge at the memory floor. Bench shape P=8192, H=32: 270.5 MB read, 135.3 MB written, copy-model floor 92.8 us, baseline 99..105 us, headroom 1.05..1.14. Nothing is re-read, so there are no bytes to save; 1.5x is out of reach in principle. No verified win; `baseline` is shipped (within tolerance of the original -O3 binary, not bit-identical: -ffast-math, 6/78 cases identical).

### Time split (probes, us)
| part | us |
|---|---|
| full kernel, one row per wave (912225486e161830) | 99.3 |
| without the s_merged store | 98.6 (store 0.7) |
| s_a/s_b scalar loads replaced by constants | 99.1 (0.2) |
| empty body, 262144 workgroups x 1 wave | 58.0 |
| empty body, 131072 x 1 wave (earlier session) | 31.2 |
| empty body, 16384 workgroups x 16 waves | 17.1 |
| scale arithmetic + s loads (earlier session) | ~3 |
| v_merged store (earlier session) | ~11 |

Dispatch is ~0.16..0.22 us per workgroup when nothing else happens, but it is hidden behind the memory time: the full kernel takes ~100 us at 16384, 65536, 131072 and 262144 workgroups. The time is the row loads and the store.

### amdclang's code against the best hand-written bodies
`isa_diff(baseline, 25295ae0ece47d67)`: 74 -> 69 instructions; vector 4 B loads 2 -> 0 (s_a/s_b by `s_load_dword`), SALU +13 (bases by `s_mul_i32`, `s_lshl_b64`, `s_add_u32`/`s_addc_u32`), VALU add/sub -8, bit ops -4, compares -2 (no per-lane 64-bit addressing, no `v_cmp_gt_u32` + `s_and_saveexec_b64` bounds mask), waits 6 -> 4, branches 2 -> 1; block 64 -> 32, grid P*H exact. The row accesses stay `global_load_dwordx4` x2 and `global_store_dwordx4`, addressed as scalar base + 32-bit vector offset (`v8 = tid << 4`). 912225486e161830 is the same with `dwordx2` on 64 lanes. Both measure 1.011..1.014 over the baseline, CI touching 1.01: parity.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| one row per 32-lane workgroup, dwordx4 (block 32) | like the 64-lane dwordx2 body | 25295ae0ece47d67: 1.014 (1.008..1.022, 240 pairs); 0.993 against 912225486e161830 | parity |
| re-time previous best 912225486e161830 | 1.039 claimed | 1.011 (1.003..1.024); harness earlier 1.006 | parity, not reproduced |
| two rows per wave, 4 row loads in flight (rb_scal recipe) | parity or loss (silu, axpy) | 5e66eafb5ea75e97: 0.980 (0.974..0.989) | loses |
| 4 rows per wave, pipelined (next rows' loads before the current store) | recover dispatch | c08165ec0e64d11b: 0.937 (0.928..0.948) | loses |
| 16 waves per workgroup (block 1024) | dispatch 58 -> 17 us if additive | 8ef7112bced026c9: 1.004 (0.996..1.015) | parity: dispatch is not additive |
| 4 B per lane, 256 B per wave | loss (axpy) | 858d4ad0debbfd46: 0.963 (0.957..0.968) | loses |
| one s_load_dwordx16 for the kernargs | <= 0.2 us | ee584bdc981f8d5f: 0.999 against parent (240 pairs) | parity |

Together with session 1 (coarsen 2/4/8 0.93..0.98, blocks 128/256 parity, bare v_exp parity, load order parity) every lever family has been measured: bytes per lane (4, 8, 16), bytes per wave (256 B .. 2 KB), waves per workgroup (0.5, 1, 2, 4, 16), loads in flight (2, 4, pipelined), prologue and arithmetic.

### Untested
A source-level build of the one-row-per-wave geometry (would be credited to amdclang; the machine-level version is parity anyway). Non-temporal or cache-bypassing stores do not exist in the ISA. Nothing else is expected to give more than 1 %.

### Tried

| what | outcome | speedup |
|---|---|---|
| Two rows per wave (1 KB per stream per wave) as two dwordx2 x 64-lane tiles, all 4 row loads + 4 scalar loads in flight before the first wait, row1 clamped to total-1 (branch-free odd tail), grid cdiv(P*H,2) | loss | 0.980 (0.974..0.989, 120 pairs) |
| One row per 32-lane workgroup: block 32, global_load_dwordx4 per lane (512 B per stream per half-filled wave), grid P*H exact, scalar addressing | parity (first 120-pair run 1.046 was a slow-baseline run) | 1.014 (1.008..1.022, 240 pairs); 0.993 (0.989..1.002) against 912225486e161830 |
| One-row-per-wave body at block 1024 (16 waves per workgroup, 16384 workgroups) | parity | 1.004 (0.996..1.015, 120 pairs) |
| 4 rows per wave, software-pipelined: row i+2's loads issued before row i's store (4 dwordx2 loads in flight throughout), waits vmcnt(3)/(2)/(4)/(3)/(5)/(4) from fix_waits, rows clamped, grid cdiv(P*H,4) | loss | 0.937 (0.928..0.948, 120 pairs) |
| 4 B per lane: half a row (256 B per stream) per wave, block 128 = one row per 2-wave workgroup, v_mul + v_fmac | loss | 0.963 (0.957..0.968, 120 pairs) |
| Prologue trim on the one-row-per-wave body: one s_load_dwordx16 for all kernargs instead of x8 + x4 + dword | parity against its parent | 0.999 (0.993..1.007, 240 pairs) against 912225486e161830 |
| Re-timing of the previous session's best (one row per wave, dwordx2 x 64 lanes, exact grid) | parity (1.039 of the earlier session not reproduced) | 1.011 (1.003..1.024, 120 pairs) |
| Probes on the one-row-per-wave body: no s_merged store / s_a,s_b loads replaced by constants / empty body at 262144 x 1 wave / empty body at 16384 x 16 waves | diagnostic: 98.6 us / 99.1 us / 58.0 us / 17.1 us against 99.3 us full | n/a |
