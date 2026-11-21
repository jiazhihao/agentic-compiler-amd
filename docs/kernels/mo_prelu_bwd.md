# `mo_prelu_bwd`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 07:18

**Harness verdict:** fallback: the named state bb83d220b0573d74 did not verify as a win: parity; outputs bit-identical to the original binary on 50 cases

## mo_prelu_bwd: at the memory floor, parity explained

**Case:** every tensor element is touched exactly once (input and output_grad read, input_grad and weight_grad_collector written; weight is one scalar). 537 MB read + 537 MB written in 191 to 198 us = 5.6 TB/s; `reference_headroom` 1.01 to 1.05. The copy model is accurate here; 1.5x is out of reach without moving fewer bytes, and both outputs must be fully written.

### Hot path of the baseline (amdclang, EPT=2, block 128, grid N/256)
Loop-free for full workgroups (the loop `.LBB0_8` is the tail only). Per wave: `s_load_dwordx4` + `s_load_dwordx8` kernargs (two scalar round trips), two 64-bit index compares with `s_and_saveexec`, three `v_lshl_add_u64` addresses, 2 `global_load_dwordx2`, `s_load_dword` weight, `s_waitcnt vmcnt(1)` / `vmcnt(0) lgkmcnt(0)`, `v_pk_mul_f32` + 2 `v_cmp_lt_f32` + 2 `v_cndmask` (+ `s_nop 1` for the VCC hazard), `global_store_dwordx2`, then `s_waitcnt vmcnt(0)` (waits for the first store), `v_pk_mul_f32` + 2 `v_cmp_nlt_f32` + 2 `v_cndmask`, `global_store_dwordx2`. About 45 instructions executed per wave for 1 KB read and 1 KB written.

### Time split (probes on the hand-written state A, same geometry)
| variant | time |
|---|---|
| complete (A, e1625937d632e9c5) | 193.5 us |
| without the weight_grad_collector store (541fc4bedde918f3) | 160.2 us |
| without both stores (60153853818b7860) | 126.6 us |
| without the loads, constants stored (a9f6f16b0a09cdf1) | 83.9 us |

Launch about 20 us; two load streams about 107 us (5.0 TB/s); each store stream about 33 us (8.1 TB/s). 20 + 107 + 66 = 193: the phases are additive, and the arithmetic, masks and waits are below the measurement.

### ISA-level difference, amdclang against the hand-written state A
`isa_diff(baseline, e1625937d632e9c5)` counts the prepended fast path on top of amdclang's code (which stays as the tail): +18 SALU, +4 branches, +2 `global_load_dwordx2`, +2 `global_store_dwordx2`, +4 `v_mul_f32`, +4 `v_cndmask_b32_e64`, +2 `v_cmp_lt_f32_e64`. On the executed fast path A replaces: the two per-lane 64-bit compares and `s_and_saveexec` regions by one scalar `s_sub_u32` / `s_subb_u32` bound test; three `v_lshl_add_u64` by `s_add_u32` / `s_addc_u32` on the bases and scalar-base addressing (`global_load_dwordx2 v, v_off, s[base]`); four float compares by two `v_cmp_lt_f32_e64` into SGPR pairs shared by both outputs (no `s_nop`); the wait on the first store by a single `s_waitcnt vmcnt(0) lgkmcnt(0)` before both computations. Result: 0.994, parity.

### Opportunities
| what | expected | measured | verdict |
|---|---|---|---|
| A: mask-free scalar-base body, one wait, shared masks, same geometry | at most the arithmetic share (about 0) | e1625937d632e9c5, 0.9941 (0.9927..0.9973) | parity |
| B: one wave per workgroup, 1 KB per wave, 4 loads in flight (rb_scal recipe) | up to 1.12x by analogy | a0d53e99825fd815, 0.9658 (0.9635..0.9674) | loses |
| C: block 256, 512 B per wave | fewer workgroups | 71dc08f919e3e9da, 0.9472 (0.9454..0.9493) | loses |
| D: block 64, 512 B per wave | more, shorter workgroups | 8950d60ea26a622b, 0.9623 (0.9596..0.9664) | loses |
| E: 16 B per lane dwordx4, block 128 | half the waves | cba6b92d4c71048a, 0.8954 (0.8934..0.8983) | loses |
| F: two tiles per wave, next tile's loads before the current stores, block 128 | half the workgroups, loads overlapping stores | 79d2b718c36c8484, 0.9498 (0.9451..0.9535) | loses |
| coarsen 2 / 4 / 8 (earlier session) | fewer launches | 1.0002 / 0.9591 / 0.8725 | parity / loses / loses |
| kernarg loads merged at entry (earlier session) | one scalar round trip | 05a16eaad748e2f7, 1.0034 | parity |

All timings 240 pairs; the baseline's own time moved between 191.0 and 198.2 us across runs.

### Untested, and why
- 4 B per lane (EPT=1): lost on rb_axpy (0.93) and is a step away from the optimum found here.
- Reversed traversal, load order, 2D grid: parity on rb_axpy / rb_swap, same class.
- Block 512 / 1024: the trend from block 128 to 256 (0.947) is already negative.
- Nothing can reduce the bytes: both outputs are dense and checked with poisoned buffers, and each input is read once.

The shipped state is `baseline`; `equivalent(baseline)` is bit-identical to the original binary on 50/50 cases. States A to F are computed with the same single multiply per element and passed the full battery (49/49).

### Tried

| what | outcome | speedup |
|---|---|---|
| A: mask-free scalar-base fast path for full workgroups at amdclang's geometry (block 128, grid N/256, 512 B/wave); one s_load_dwordx8 + dwordx4 at entry, scalar 64-bit bound test, both outputs computed under one wait before either store, compare masks shared between outputs in SGPR pairs; amdclang's code kept as tail path | parity | 0.9941 |
| B: block 64, grid N/256, 1 KB contiguous per wave as two 512 B tiles, 4 dwordx2 loads in flight, pipelined vmcnt(2) waits (rb_scal recipe), on amdclang's EPT=4/BLK=64 build as tail host | loss | 0.9658 |
| C: block 256 (4 waves per workgroup), grid N/512, 512 B/wave, mask-free fast path | loss | 0.9472 |
| D: block 64 (one wave per workgroup), grid N/128, 512 B/wave, mask-free fast path | loss | 0.9623 |
| E: 16 B per lane (global_load_dwordx4 / global_store_dwordx4), block 128, grid N/512, 1 KB/wave | loss | 0.8954 |
| F: block 128, grid N/512, two 512 B tiles per wave 1 KB apart, tile B's loads issued before tile A's stores, vmcnt(2) pipelined | loss | 0.9498 |
| coarsen factor 2 / 4 / 8 on the baseline (earlier session, not repeated) | parity / loss / loss | 1.0002 / 0.9591 / 0.8725 |
| both kernarg loads at entry under one wait (earlier session, not repeated) | parity | 1.0034 |
| probe: fast path without the weight_grad_collector store | diagnostic, 160.2 us (193.5 us complete) | None |
| probe: fast path without both stores | diagnostic, 126.6 us | None |
| probe: fast path without the loads (stores of constants) | diagnostic, 83.9 us | None |
| amdclang source variants EPT/BLK = 4/64, 2/256, 4/128, 2/64 used only as tail-path hosts for B to F; not timed on their own | not timed | None |

## Session 2026-11-21 07:22

**Harness verdict:** fallback: the named state bb83d220b0573d74 did not verify as a win: parity; outputs bit-identical to the original binary on 50 cases

## mo_prelu_bwd, session 2: memory floor confirmed, parity explained

**Case:** every tensor element touched exactly once (input, output_grad read; input_grad, weight_grad_collector written; weight is one scalar). 537 MB read + 537 MB written in 191 to 197 us (5.4 to 5.6 TB/s); `reference_headroom` 1.01 to 1.04 in this session's runs. Nothing can reduce the bytes: both outputs are dense and checked with poisoned buffers. 1.5x is out of reach.

### Hot path (unchanged from the earlier analysis)
amdclang's EPT=2 / block 128 build is loop-free for full workgroups: per wave 2 `global_load_dwordx2`, `s_load_dword` weight, `v_pk_mul_f32` + 2 compares + 2 `v_cndmask` per output, 2 `global_store_dwordx2`; about 45 instructions for 1 KB read and 1 KB written. Time split from the earlier session's probes (not repeated): launch about 20 us, two load streams about 107 us, each store stream about 33 us; arithmetic, masks and waits below the measurement.

### ISA-level difference of the shipped state
The shipped state is amdclang's own build (`baseline`), so there is none. The only machine-level candidate of this session (G, d48c7485b1aa97e4) adds 8 scalar instructions at entry (`s_add_u32`/`s_addc_u32`/`s_lshr_b64` for cdiv(N,512), `s_and_b32`, `s_lshr_b32`, `s_cmp_eq_u32`, `s_cselect_b32`, `s_add_u32`) to remap the workgroup id; the body is identical.

### Opportunities measured in this session
| what | expected | measured | verdict |
|---|---|---|---|
| 4 B per lane, block 128 (256 B/wave) | listed untested; a step away from the optimum | c1379b4272441803, 0.8473 (0.8445..0.8495) | loses |
| 12 B per lane (`global_load_dwordx3`), block 128 (768 B/wave) | between 8 B and 16 B | 99d3247d20fc890d, 0.8839 (0.8776..0.8886) | loses |
| block 192 (3 waves per workgroup), 512 B/wave | between block 128 and 256 | adea90162cf55122, 0.9319 (0.9242..0.9381) | loses |
| G: workgroup-id interleave, two streaming fronts per tensor | unknown; different kind (dispatch order) | d48c7485b1aa97e4, 0.9808 (0.9798..0.9837), 240 pairs | loses |

Together with the earlier session (A mask-free fast path 0.994, B 4 loads in flight 0.966, C block 256 0.947, D block 64 0.962, E 16 B/lane 0.895, F next tile's loads before stores 0.950, coarsen 2/4/8 1.000/0.959/0.873, merged kernarg loads 1.003) the geometry space is mapped: 8 B per lane, 2 waves per workgroup, sequential workgroup order is a local optimum in every direction tried.

### Untested, and why
- 2D grid / reversed traversal: parity on rb_axpy and rb_swap; G shows that departing from sequential order costs rather than pays.
- Block 512 / 1024: trend negative from 128 upward.
- Fewer bytes: impossible, both outputs dense.

`equivalent(baseline)`: bit-identical to the original binary on 50/50 cases.

### Tried

| what | outcome | speedup |
|---|---|---|
| EPT=1 BLK=128 (amdclang source variant): 4 B per lane, 256 B per wave, grid N/128 | loss | 0.8473 |
| EPT=3 BLK=128 (amdclang source variant): 12 B per lane with global_load_dwordx3 / global_store_dwordx3, 768 B per wave | loss | 0.8839 |
| EPT=2 BLK=192 (amdclang source variant): 3 waves per workgroup, 1.5 KB per workgroup, 512 B per wave | loss | 0.9319 |
| G (machine IR on baseline): workgroup-id interleave at entry (even ids -> first half of the arrays, odd ids -> second half; 8 scalar instructions, bijection for any N), body unchanged: two streaming fronts per tensor | loss | 0.9808 |
| Earlier session's A-F, coarsen 2/4/8, merged kernarg loads: not repeated | parity / loss | None |
