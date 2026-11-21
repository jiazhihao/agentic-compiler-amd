# `mo_active_fwd`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 07:27

**Harness verdict:** fallback: the named state c199f2d77f8fdf2a did not verify as a win: parity; outputs bit-identical to the original binary on 50 cases

## mo_active_fwd (leaky ReLU, f4 per thread) — memory-floor case

**Case:** every element is read once and written once (268.4 MB each way at Q = 2^24). Baseline 107.8 us, model floor 104.7 us, headroom 1.03. The 1.5x target is out of reach; best measured machine-level state is parity.

### Baseline code (amdclang, -ffast-math, block 64, grid cdiv(Q,64))
32 instructions, loop-free: `s_load_dword` (Q) + wait, `v_cmp_gt_u32` + `s_and_saveexec` + branch, `s_load_dwordx4` + `s_load_dword` (alpha) + wait, 64-bit per-lane addresses (`v_lshlrev_b64`, 2 `v_lshl_add_u64`), one `global_load_dwordx4`, `s_waitcnt vmcnt(0)`, 4 x (`v_cmp_ge_f32` -> vcc, `s_nop`, `v_cndmask` 1.0/alpha), 2 `v_pk_mul_f32`, one `global_store_dwordx4`. 3 waits (all full), 7 nop wait states. One wave per workgroup, 1 KB contiguous per wave: already the geometry that won on rb_scal.

### Time split (probes on the mask-free state A, 262144 one-wave workgroups)
| variant | us |
|---|---|
| complete | 107.8 |
| store deleted | 87.0 |
| load replaced by constants (store only) | 61.6 |
| neither (kernarg load + compare + endpgm) | 58.2 |
| neither, 131072 waves (D geometry) | 30.7 |

Not additive: the empty kernel is already 58 us (wave dispatch, ~0.21 us per 1000 waves), the store adds 3.4 us alone but 21 us after a load, the load adds 29 us alone. Arithmetic, masks, nops and scalar loads are invisible (A = parity). Halving the waves halves the dispatch probe but the full kernel gets slower (117 us): dispatch overlaps with the memory stream.

### ISA difference baseline -> A (isa_diff, fast path only)
A's fast path: 1 `s_load_dwordx8` (instead of 3 scalar loads, 2 waits), 6 SALU for the 64-bit bases (instead of 3 per-lane 64-bit VALU), `global_load_dwordx4 v[0:3], v4, s[4:5]` (scalar base + 32-bit lane offset), 4 `v_mul_f32` by `s11`, 4 `v_cmp_ge_f32_e64` into SGPR pairs, 4 `v_cndmask_b32_e64`, no nops, no exec mask; bit-identical (x*1.0 == x). Static totals are larger (61 vs 32) only because amdclang's code is kept as the tail.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| A mask-free fast path, scalar bases, 1 kernarg load, no nops | <= few us of VALU/SMEM | 4e6cd70b97733348: 1.0009 (0.9945..1.0043, 240 pairs) | parity |
| B two 512 B x2 loads in flight, pipelined vmcnt(1) | rb_scal 1.12x (but geometry already there) | b0ce91fa40eb3796: 1.0015 (0.9966..1.0034) | parity |
| D 2 KB per wave, 2 x4 loads in flight, half the waves | up to -27 us dispatch | cdabba688e4877a4: 0.9312 (0.922..0.939) | loss |
| C block 256 (4 waves/wg) | fewer workgroups | ed89d596c6f3e5e2: 0.9829 (0.977..0.990) | loss |
| G block 128 (2 waves/wg, 1 KB each) | fewer workgroups | e614415d0c1f1f63: 0.9751 (0.971..0.985) | loss |
| F 8 B per lane, block 128, 512 B per wave | prelu optimum was 8 B/lane | 902817841f63d59d: 0.9869 (0.983..0.993) | parity/loss |
| coarsen 2 / 4 / 8 (earlier session) | fewer launches | 0.969 / 0.957 / 0.912 | loss |

### Untested
4 KB or more per wave (copy study: 0.79 at 64 B per lane), workgroup-id interleave (0.98 on mo_prelu_bwd), half-wave workgroups (block 32). All are in families that lost here or on sibling kernels. The only remaining lever is fewer bytes (in-place operation, fusing with the neighbouring layer), which is outside this kernel's contract.

`equivalent(baseline)`: bit-identical to the original binary on 50 cases.

### Tried

| what | outcome | speedup |
|---|---|---|
| A: mask-free fast path for full workgroups (one s_load_dwordx8, scalar bases advanced by wg<<10, 32-bit lane offset, 4 v_mul by alpha + 4 v_cmp_ge_e64 into SGPR pairs + 4 v_cndmask_e64, no nops, no s_and_saveexec), amdclang code as tail | parity | 1.0009 |
| B: same 1 KB per wave as two 512 B global_load_dwordx2 in flight (offset 0 / 512) with pipelined vmcnt(1) waits and two stores (the rb_scal recipe) | parity | 1.0015 |
| D: 2 KB per wave (32 B per lane, two dwordx4 loads in flight at offset 0 / 1024, pipelined waits), grid cdiv(Q,128) block 64, masked two-step tail loop | loss | 0.9312 |
| C: mask-free body at block 256 (4 waves per workgroup), grid cdiv(Q,256) | loss | 0.9829 |
| G: mask-free body at block 128 (2 waves per workgroup, 1 KB each), grid cdiv(Q,128) | loss | 0.9751 |
| F: 8 B per lane (dwordx2), block 128, two 512 B waves per workgroup, grid cdiv(Q,64) | parity (CI entirely below 1: 0.983..0.993) | 0.9869 |
| coarsen factor 2 / 4 / 8 on the baseline (earlier session) | loss | 0.9688 |
| probes (diagnostic, not results) on A: no store 87.0 us; no load 61.6 us; neither 58.2 us; D geometry (131072 waves) with neither 30.7 us | diagnostic | None |

## Session 2026-11-21 07:31

**Harness verdict:** fallback: the named state c199f2d77f8fdf2a did not verify as a win: parity; outputs bit-identical to the original binary on 50 cases

## Session 2 — mo_active_fwd (leaky ReLU, f4 per thread): memory-floor case, confirmed

**Case:** every element read once and written once (268.4 MB each way at Q = 2^24). Baseline 106 to 108 us, model floor 104.7 us, headroom 1.03. Target 1.5x is out of reach; the best machine-level state is parity. `equivalent(baseline)`: bit-identical to the original binary on 50 cases.

### Time split
Taken from the earlier session's probes (not re-measured): empty kernel with 262144 one-wave workgroups 58 us, store only 62 us, load only 87 us, complete 108 us. Arithmetic, masks, nops and scalar loads are invisible. Dispatch overlaps the memory stream, so removing waves does not remove time.

### Baseline hot path (32 instructions, loop-free)
3 scalar loads with 2 full lgkm waits, `v_cmp_gt_u32` + `s_and_saveexec_b64`, per-lane 64-bit addresses (`v_lshlrev_b64`, 2 `v_lshl_add_u64`), one `global_load_dwordx4`, `s_waitcnt vmcnt(0)`, 4 x (`v_cmp_ge_f32` -> vcc, `s_nop`, `v_cndmask`), 2 `v_pk_mul_f32`, one `global_store_dwordx4`.

### Opportunities measured this session (kinds not tried before)
| what | expected | measured | verdict |
|---|---|---|---|
| H half-wave workgroups (block 32, 512 B/wg, 524288 wgs) | more, shorter streams | edd556f7c25da0a4: 0.9067 (0.9006..0.9119) | loss |
| I reverse-order walk on the mask-free fast path | different page/TLB order | 5fd0a1ab77b48f8e: 0.9940 (0.9908..0.9963, 240 pairs) | parity |
| K two far-apart 1 KB chunks per wave, both loads in flight, half the waves | -27 us dispatch while keeping 1 KB contiguous streams | 3e9cd2176a4b2bc8: 0.9168 (0.9052..0.9259) | loss |
| L 2-D grid 1024 x 256 (source level) | cheaper dispatch | 0bfbfcbe2113c99c: 1.0017 (0.9981..1.0037) | parity |

Together with session 1 (mask-free fast path 1.001, two x2 loads in flight 1.002, 2 KB per wave 0.931, block 128 0.975, block 256 0.983, 8 B per lane 0.987, coarsen 2/4/8 0.97/0.94/0.88): one full wave per workgroup, 1 KB contiguous per wave, one load and one store is the optimum, and amdclang's build already has it.

### ISA difference
None shipped. K against the baseline: 1 `s_load_dwordx8` instead of 3 scalar loads, scalar 64-bit bases, 2 `global_load_dwordx4` (scalar base + 32-bit lane offset) in flight under `s_mov_b64 exec` masks, 2 `s_waitcnt vmcnt(1)`, 8 `v_mul_f32` by `s11` + 8 `v_cmp_ge_f32_e64` into SGPR pairs + 8 `v_cndmask_b32_e64`, 2 stores, no nops.

### Untested
4 KB or more per wave and workgroup-id interleaving (both in families that lost here or on siblings). The only remaining lever is fewer bytes (in-place operation or fusion with the neighbouring layer), outside this kernel's contract.

### Tried

| what | outcome | speedup |
|---|---|---|
| H: half-wave workgroups: block 32, grid cdiv(Q,32), 512 B per workgroup (baseline code with the workgroup shift 6 -> 5) | loss | 0.9067 |
| I: mask-free fast path walking the arrays in reverse order (chunk = Q/64 - 1 - wg), tail unchanged | parity (60 pairs 1.0047, CI 0.9985..1.0108; 240 pairs 0.9940, CI 0.9908..0.9963) | 0.994 |
| K: half the waves, each wave handles two far-apart 1 KB chunks (i and i + cdiv(G,2)), both dwordx4 loads in flight under their own exec masks, pipelined vmcnt(1), grid cdiv(cdiv(Q,64),2) | loss | 0.9168 |
| L (source level, credited to amdclang): 2-D grid 1024 x cdiv(Q,65536) with the same one-wave 1 KB workgroups | parity (CI 0.9981..1.0037) | 1.0017 |
