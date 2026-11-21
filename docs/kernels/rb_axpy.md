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
