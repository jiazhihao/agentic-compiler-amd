# `rb_axpy`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 05:41

**Harness verdict:** fallback: the session named no state faster than the baseline

## rb_axpy: ISA-level analysis

**Case:** memory floor, every element touched once (x read, y read and written). Baseline headroom 0.94 to 0.95 against the copy model (5.2 TB/s). 1.5x is out of reach without moving fewer bytes, and axpy has none to save. Result: baseline ships; all machine-level candidates are parity, loss, or not reproducible.

### amdclang's code (state `ref`, 41 instructions, loop-free)
- Block 256, grid N/512: 131072 workgroups, 524288 waves, each wave one 512 B tile of x and of y.
- Hot path: `s_load_dwordx2` + `s_load_dwordx4` (kernargs), `v_cmp_eq_f32` alpha test, 64-bit index compare and `s_and_saveexec_b64`, two `v_lshl_add_u64`, two `global_load_dwordx2`, one `s_waitcnt vmcnt(0)`, one `v_pk_fma_f32`, one `global_store_dwordx2`, then the odd-tail test (`v_cmp_eq_u64`, second saveexec) that is skipped on execz.
- 5 waits, all for everything; no loop, no LDS.

### Time split (probes of the baseline, diagnostic)
| Variant | Time | Implied |
|---|---|---|
| full kernel | 154 to 158 us | |
| no store (`3ebdcfa182732782`) | 134.0 us | store about 22 us |
| no x load (`815e97d3bb98d62b`) | 104.6 us | x load about 51 us |
| no loads, no store (`79726ad7a38dbd94`) | 31.8 us | launch + waves + index about 32 us; y load about 51 us |

### Opportunities, expected and measured (all 240 pairs against the baseline)
| What | Expected | State | Measured | Verdict |
|---|---|---|---|---|
| One wave per workgroup, 1 KB per wave, 4 loads in flight (rb_scal recipe) | up to 1.12 (rb_scal) | `d82054e14c14b81c` | 0.974 (0.970..0.976) | loses |
| Two sequential tiles per wave, 2048 B apart, mask-free fast path (half the waves) | part of the 12 us wave overhead, about 1.03 | `bde630c55b36bbd2` | 1.034 (1.031..1.037), repeat 1.009 (1.005..1.011) | parity (not reproducible) |
| Same with tile B loads in flight before tile A's store, `vmcnt(1)` | a few us of latency | `be86f36bcac4cba2` | 1.027 (1.024..1.030), one run, slow-baseline condition | unconfirmed, no better than H1 |
| Same with 1 KB contiguous per wave | equal to H1 (rb_scal) | `1a9c9971dbfbd0af` | 0.962 (0.959..0.965) | loses |
| Block 128, two tiles per wave | between baseline and H1 | `95733e125d8bd9d3` | 0.997 (0.994..1.000) | parity |
| Fewer instructions at amdclang's geometry (scalar alpha test, no masks) | under 1 % | `07c7449cdc0ee15a` | 1.000 (0.997..1.002) | parity |
| Coarsen 2 with hoisting (earlier session) | 1.03 as recorded | `a4cb5c4521756f8f` | 1.040 (1.038..1.043), repeat 0.983 (0.980..0.987) | not reproducible |

### Measurement caveat
The baseline's time is bimodal between runs (about 154 to 157 us or 161 to 165 us); the two-tile candidates stay at 155 to 159 us in both. Every "win" above was taken in a slow-baseline run, every repeat in a fast-baseline run came out parity or loss. Under the harness rule (lower of two 240-pair timings) none is a win. What sets the baseline's mode is unknown (not identified in this session).

### ISA-level difference of the hand-written bodies from amdclang's
`s_lshl_b32`/`s_cmp_eq_u32` on alpha's bits instead of `v_cmp_eq_f32` + `s_and_b64 vcc`; one scalar compare `(wg+1)*tile <= n` selecting a mask-free path instead of `v_cmp_gt_i64` + `s_and_saveexec_b64` + `v_cmp_eq_u64` + second saveexec; two `v_fmac_f32_e32` with the scalar alpha instead of `s_mov_b32` + `v_pk_fma_f32` (same fused operation, bit-identical by construction; `equivalent` was not run since the baseline is reported); second tile addressed through the load/store `offset:` field. None of it changes the time.

### Untested
- More than two sequential tiles per wave with hoisting (coarsen 4 and 8 unhoisted lost in an earlier session).
- Load order (x before y) and non-temporal or differently aligned stores.
- Whether the baseline's slow mode is a buffer-alignment effect; if so a geometry that is insensitive to it would be a real gain of 0 to 4 %.

### Tried

| what | outcome | speedup |
|---|---|---|
| rb_scal recipe: block 64 (one wave per workgroup), grid N/256, 1 KB contiguous of x and of y per wave, 4 dwordx2 loads in flight (second chunk via offset:512), vmcnt(2)/vmcnt(1), mask-free fast path | loss (240 pairs, CI 0.970..0.976) | 0.9741 |
| Earlier session's coarsen 2 with hoisted kernargs/alpha test/lane index, re-timed twice at 240 pairs | unstable: win 1.040 (CI 1.038..1.043, baseline at 161.5 us) then loss 0.983 (CI 0.980..0.987, baseline at 153.9 us); not a safe win | 0.9833 |
| H1: hand-written, block 256, grid N/1024, two 512 B tiles per wave 2048 B apart, strictly sequential load/wait/fma/store per tile, mask-free fast path, masked 2-step tail path | win 1.034 (CI 1.031..1.037) on the first run, parity 1.009 (CI 1.005..1.011) on the second; parity by the lower-of-two rule | 1.0089 |
| H2: H1 with tile B's two loads issued before tile A's fma and store, second wait weakened to vmcnt(1) | win on a single 240-pair run (CI 1.024..1.030) taken while the baseline ran slow (163 us); not repeated, 0.8 % below H1 in the same condition, so not trusted | 1.0265 |
| H3: H1 but each wave owns 1 KB contiguous (tile B at +512 B instead of +2048 B) | loss (240 pairs, CI 0.959..0.965) | 0.9621 |
| H4: block 128 (2 waves per workgroup), grid N/512, two sequential 512 B tiles per wave 1024 B apart, mask-free fast path | parity (240 pairs, CI 0.994..1.000) | 0.9969 |
| H5: amdclang's geometry (block 256, grid N/512, one 512 B tile per wave) with a hand-written body: scalar alpha test, no 64-bit compares, no exec masks on full workgroups, 2 v_fmac instead of v_pk_fma | parity (240 pairs, CI 0.997..1.002) | 1.0004 |
| Probes of the baseline (diagnostic only): no store 134.0 us; no x load 104.6 us; no loads and no store 31.8 us | not results; time split only | None |
| Intermediate states with no timing of their own: block-128 and one-tile code before relaunch | not timed (launch inconsistent until relaunched) | None |
| From earlier sessions, not repeated: coarsen 2/4/8 (0.995/0.976/0.966), -ffast-math source (0.967), 16 B per lane source (0.970), block 1024 source (0.982), block 64 source (1.007), straight-line coarsen 2 with 4 loads in flight (0.973) | parity or loss as recorded | None |

## Session 2026-11-21 05:46

**Harness verdict:** fallback: the session named no state faster than the baseline

## rb_axpy: ISA-level analysis (session 2)

**Case:** memory floor, every element touched once (x read, y read and written: 537 MB read, 268 MB written). Baseline headroom 0.94 to 0.99 against the copy model, 4.9 to 5.2 TB/s. 1.5x is not possible without moving fewer bytes, and axpy has none to save. Baseline ships; nothing in two sessions is a reproducible win.

### amdclang's code (state `ref`, 41 instructions, loop-free)
Unchanged from session 1: block 256, grid N/512, each wave one 512 B tile of x and y, 8 B per lane. Hot path: `s_load_dwordx2` + `s_load_dwordx4`, `v_cmp_eq_f32` alpha test, `v_cmp_gt_i64` + `s_and_saveexec_b64`, two `v_lshl_add_u64`, two `global_load_dwordx2` (y first, then x), one `s_waitcnt vmcnt(0)`, one `v_pk_fma_f32`, one `global_store_dwordx2`, odd-tail test skipped on execz. 5 waits, all for everything.

### Time split
From session 1's probes (not repeated): launch + waves + index about 32 us, x load about 51 us, y load about 51 us, store about 22 us of 155 us. The loads are 2/3 of the time and are already issued together under one wait.

### Opportunities measured this session (240 pairs each, against the baseline)
| What | Expected | State | Measured (CI) | Verdict |
|---|---|---|---|---|
| A: two tiles per wave half an array apart (two independent streams), mask-free fast path | unknown; tests whether stream locality or wave count matters | `5f6686cd997a9080` | 0.945 (0.939..0.950) | loses |
| B: four sequential tiles per wave 2 KB apart, hoisted (session 1's untested item) | part of the 32 us overhead | `b059a03a9465b17c` | 0.954 (0.951..0.957) | loses |
| E: waves of a workgroup interleaved at 8 B granularity (lane permutation) | unknown; cache-line sharing between waves | `3fe9c8f68072ef9c` | 0.814 (0.810..0.816) | loses |
| F: x load before y load (session 1's untested item) | under 1 % | `c6115720d1996b05` | 0.997 (0.994..0.999) | parity |
| P: software prefetch 8 MB ahead, one lane per 64 B line, unwaited | a few % if the cache kept the lines | `b67ce4c1ae992e62` | 0.939 (0.937..0.942) | loses |
| G: reversed traversal (workgroup g owns tile W-1-g) | unknown; dispatch order vs address order | `e4a7cf8b78f8551d` | 0.998 (0.996..1.001) | parity |

Together with session 1 (one wave per workgroup with 4 loads in flight 0.974; two tiles per wave 1.009; with loads in flight unconfirmed; 1 KB contiguous per wave 0.962; block 128 0.997; fewer instructions 1.000; coarsen 2 hoisted 0.983), 13 machine-level candidates of the launch-geometry, loads-in-flight, instruction-count, lane-mapping, ordering and prefetch kinds are parity or loss.

### ISA-level difference from amdclang's code
The shipped state is amdclang's. The hand-written bodies (A, B) replace `v_cmp_eq_f32` + `s_and_b64 vcc` by `s_lshl_b32`/`s_cmp_eq_u32` on alpha's bits, the 64-bit `v_cmp_gt_i64` + two `s_and_saveexec_b64` by one scalar `s_cmp_le_u32` selecting a mask-free path, `v_pk_fma_f32` by two `v_fmac_f32_e32` with scalar alpha (same fused operation), and add a scalar tile loop (`s_add_u32`, `s_add_i32`, `s_cmp_lg_u32`, `s_cbranch_scc1`). None of this changes the time; the extra tiles per wave lose. `equivalent` was not run because the baseline itself is reported.

### Measurement caveat (confirmed)
The baseline is bimodal between bench invocations: 155.3 to 155.6 us (three runs) or 162.5 to 162.7 us (three runs) in this session. A state at amdclang's geometry follows the mode (G: 163.1 us against 162.6 us). Session 1's two-tile states sat near 157 us in both modes, which explains their unreproducible "wins".

### Untested
- What sets the baseline's slow mode (buffer placement or clock level); a harness question, not a kernel one.
- Non-temporal stores or alignment-dependent stores: no ISA-level way found to express them.
- Block 512 at one tile per wave (block 64 and 1024 at source level were 1.007 and 0.982, so parity is expected).

### Tried

| what | outcome | speedup |
|---|---|---|
| A: block 256, grid W/2, each wave does tile g then tile g+G (two streams half an array apart), sequential load/wait/fmac/store, mask-free fast path per tile, masked path for tails | loss (240 pairs, CI 0.939..0.950) | 0.9451 |
| B: four sequential 512 B tiles per wave, 2048 B apart, kernargs/alpha test/lane index hoisted, mask-free fast path, grid N/2048 (the 'coarsen 4 with hoisting' left untested) | loss (240 pairs, CI 0.951..0.957) | 0.9538 |
| E: lane permutation on amdclang's code: thread t -> slot (t%64)*4 + t/64, so the 4 waves of a workgroup interleave at 8 B granularity and each wave touches all 32 cache lines of the 2 KB tile | loss (240 pairs, CI 0.810..0.816) | 0.8136 |
| F: x load issued before y load (amdclang issues y first) | parity (240 pairs, CI 0.994..0.999) | 0.9968 |
| P: software prefetch: after its store each full wave issues unwaited dword loads of x and y 8 MB ahead, one lane per 64 B line (exec 0x0101..), guarded by a scalar bound test | loss (240 pairs, CI 0.937..0.942); note the battery shapes (N <= 10008) never take the prefetch path, only the bench shape does | 0.9394 |
| G: reversed traversal: workgroup g owns tile W-1-g (appended arg W-1), otherwise amdclang's code | parity (240 pairs, CI 0.996..1.001) | 0.9984 |
| G via edit + relaunch with an appended arg | refused by check (abi: kernel takes 4 arguments, launch adds 1); redone with edit_ir | None |

## Session 2026-11-21 05:49

**Harness verdict:** fallback: the session named no state faster than the baseline

## rb_axpy: ISA-level analysis (session 3)

**Case:** memory floor, every element touched once (x read, y read and written: 537 MB read, 268 MB written). Baseline 155.1 us (fast mode) or 161.5 us (slow mode), 4.85 TB/s, headroom 0.94 to 0.98 against the copy model. 1.5x is not possible without moving fewer bytes and axpy has none to save. The baseline ships; after three sessions and 15 timed machine-level candidates nothing is a reproducible win.

### amdclang's code (state `ref`, 41 instructions, loop-free)
Unchanged: block 256, grid N/512, one 512 B tile of x and of y per wave (8 B per lane). `mix`: 2 scalar loads (`s_load_dwordx2`, `s_load_dwordx4`), 2 `global_load_dwordx2` + 2 `global_load_dword` (odd tail, skipped on execz), 1 `v_pk_fma_f32` + 1 `v_fmac_f32`, 1 `global_store_dwordx2` + 1 `global_store_dword`, 5 waits (all for everything), 3 VALU compares, 10 SALU, 3 branches. On the hot path: both loads issued together, one `s_waitcnt vmcnt(0)`, one fused multiply-add, one store.

### Time split (session 1's probes, not repeated)
Launch + waves + index about 32 us, x load about 51 us, y load about 51 us, store about 22 us of 155 us. The loads are two thirds of the time and already in flight together.

### Opportunities measured this session (240 pairs, against the baseline)
| What | Expected | State | Measured (CI) | Verdict |
|---|---|---|---|---|
| 4 B per lane, 256 B per wave (dword loads, one `v_fmac_f32_e32`, twice the waves) | unknown; smaller tiles, bytes-per-lane knob downwards | `5809ddf0996ec51a` | 0.935 (0.933..0.937), baseline fast | loses |
| Four waves of a workgroup on four streams a quarter array apart (tile g + w*G) | unknown; stream locality across waves | `980fae379c9a6549` | 0.977 (0.975..0.980), baseline slow | loses |
| Block 512, one tile per wave (session 2's untested item) | parity | `97f5f39000af8fa1` | not launchable (hip error 719) | untestable at machine level; source block 1024 was 0.982 |
| 2D grid (256 x N/131072) | parity; dispatch order | `299e94c91b8f7ce6` | static_check: s3 undefined | untestable at machine level |

Bytes per wave now has both sides measured: 256 B 0.935, 512 B 1.000 (amdclang), 1 KB 0.962 to 0.974. Address locality has both sides too: adjacent tiles for the waves of a workgroup (amdclang) beat distant streams per wave (0.945) and per workgroup (0.977), and sharing cache lines between waves (0.814).

### ISA-level difference from amdclang's code
The shipped state is amdclang's. The candidates differ by: `global_load_dword`/`global_store_dword` + one `v_fmac_f32_e32` and a 32-bit `v_cmp_gt_u32` in place of `global_load_dwordx2` + `v_pk_fma_f32` + `v_cmp_gt_i64` + the odd-tail region (S3-b); or `v_lshrrev_b32`, `v_and_b32`, `v_mul_lo_u32`, `v_add_u32` and one more `s_load_dword` in front of the index computation (S3-h). `equivalent` was not run since the baseline is reported.

### Measurement caveat
The baseline was 155.1 us in one bench and 161.5 us in the next, the same bimodality as sessions 1 and 2.

### Untested
- Block above 256 and 2D grids at the machine level (harness limits, see friction); only source builds can test them (block 1024: 0.982, block 64: 1.007).
- Non-temporal or otherwise cache-bypassing stores: no ISA-level expression found.
- What sets the baseline's slow mode.

### Tried

| what | outcome | speedup |
|---|---|---|
| S3-b: 4 B per lane, 256 B per wave: block 256, grid N/256, global_load_dword of y and x, one v_fmac_f32_e32, global_store_dword, 32-bit v_cmp_gt_u32 mask, no odd-tail path (twice the waves and workgroups of amdclang's code) | loss (battery 49/49; 240 pairs, CI 0.9327..0.9368; 166.1 us against 155.1 us, baseline in its fast mode) | 0.9345 |
| S3-h: the 4 waves of a workgroup on 4 streams a quarter array apart: wave w of workgroup g owns tile g + w*G (G = grid as appended arg at kernarg offset 24), amdclang's code otherwise | loss (battery 49/49; 240 pairs, CI 0.9746..0.9804; 165.8 us against 161.5 us, baseline in its slow mode, so the loss against the fast mode is larger) | 0.9772 |
| S3-a: block 512 (8 waves per workgroup), grid N/1024, one 512 B tile per wave, amdclang's code with the workgroup shift 9 -> 10 | not timed: check refused, hipModuleLaunchKernel code 719 'unspecified launch failure' (the imported code object does not launch above block 256); the source-level block 1024 build from an earlier session was 0.982 | None |
| S3-c: 2D grid (256, cdiv(N,131072)) with tile group = y*256 + x, to test dispatch order | not timed: static_check undefined_read of s3 (the kernel descriptor enables only workgroup id x) | None |
| From sessions 1 and 2, not repeated: one wave per workgroup with 4 loads in flight 0.974; two tiles per wave 1.009; loads of the next tile in flight 1.027 unconfirmed; 1 KB contiguous per wave 0.962; block 128 0.997; fewer instructions 1.000; coarsen 2 hoisted 0.983; two streams per wave 0.945; four tiles per wave 0.954; lane interleave 0.814; load order 0.997; software prefetch 0.939; reversed traversal 0.998 | parity or loss as recorded | None |
