# `mo_bn_infer`: ISA-level analysis

One section per agent session. The verdict line is the harness's verification; the analysis and its numbers are the session's own.

## Session 2026-11-21 07:06

**Harness verdict:** fallback: the named state 7481a6a90f3c22d7 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 1.08) on 106 cases

## mo_bn_infer: ISA-level analysis

**Case: memory floor, touch-once.** Every element of `in` is read once and `out` written once (205.5 MB each at N=256, C=256, HW4=196). The baseline runs at 88 us, headroom 1.03 to 1.04 against the copy model. The 1.5x target is out of reach; nothing measured beat the baseline.

### What amdclang's code does (state `baseline`, 71 instructions, loop-free)
- Launch: grid (cdiv(C*HW4, 64), N), block 64: one wave per workgroup, each lane one float4 (16 B), 1 KB contiguous per wave, 200704 workgroups.
- Entry block: `s_load_dwordx4`, then a per-lane unsigned division tid / hw4 (`v_rcp_iflag_f32`, `v_mul_hi_u32`, two correction steps with `v_cmp_le_u32` / `v_cndmask`, 5 nop wait states), channel bound test into EXEC.
- Body: three more scalar loads, four `global_load_dword` gathers (mean, variance, scale, bias; per lane, wave-nearly-uniform), one `global_load_dwordx4` of the input, `s_waitcnt vmcnt(1)`, `v_rsq_f32`, 2 `v_pk_add_f32`, 2 `v_pk_mul_f32`, `s_waitcnt vmcnt(0)`, 2 `v_pk_fma_f32`, one `global_store_dwordx4`.

### Time split (probes, diagnostic only; not additive)
| Variant | Time |
|---|---|
| Full kernel | 88.3 us |
| Gathers + arithmetic removed (copy) | 88.2 us |
| Store removed | 65.4 us |
| Input load replaced by zeros | 50.1 us |
| Empty kernel, same grid | 45.1 us |

So: launch + dispatch of 200704 workgroups about 45 us; the cold input read about 38 us; the store 5 us on its own and about 23 us on top of the read; gathers, division and arithmetic 0 us.

### Opportunities
| What | Expected | Measured | Verdict |
|---|---|---|---|
| Scalar loads / cheaper VALU for the per-channel parameters | 0 us by probe a69105dc03e74785 | not built | not worth it |
| Two x2 loads in flight instead of one x4 | under 1 % | 8b67e295e30702dc: 0.994 (0.984..0.999) | parity |
| Input load first, one wait (earlier session) | under 1 % | 4fc4d88c1ffd1ba3: 0.988 | loss |
| coarsen 2 / 4 / 8 (earlier session) | fewer workgroups | 0.983 / 0.905 / 0.859 | loss |
| 4 waves per workgroup (source BLK=256) | less dispatch | d99fdbd3d7223f7c: 0.969 (0.961..0.976) | loss |
| Two images per wave, loads in flight (source NPT=2) | half the workgroups | 02cc8af4a240bd1b: 0.960 (0.947..0.966) | loss |
| Grid dims swapped (x across images) | unknown | 9cb6a15b6a876a79: 0.813 (0.806..0.821) | loss |

All timings are 60-pair; none was close enough to a win to need 240 pairs.

### Differences from amdclang's code
The shipped state is amdclang's own build, so there is no ISA difference to report. `equivalent(baseline)` against `ref`: within tolerance on all 106 cases, bit-identical on 4 (the restructured source uses `v_rsq_f32` and packed fma).

### Untested
- 512 B per wave (8 B per lane, twice the workgroups) and 32 B per lane: both lost on rb_scal / the copy study (0.87, 0.94), and 32 B per lane needs a tail path for odd HW4.
- A wave-uniform scalar fast path: the probe bounds its gain at 0 us.
- Reducing the 45 us of dispatch without losing the 1 KB-per-short-wave pattern: every way of having fewer workgroups measured slower, so the dispatch cost appears to overlap with memory time rather than add to it.

### Tried

| what | outcome | speedup |
|---|---|---|
| Input read as two global_load_dwordx2 (offset 0 and offset:8) in flight instead of one global_load_dwordx4 | parity | 0.9943 |
| Traversal order: grid dims swapped (x = batch image, y = 1 KB tile), s2/s3 exchanged in the code | loss | 0.8133 |
| Source geometry BLK=256, NPT=1 (4 waves per workgroup, 50176 workgroups) | loss | 0.9688 |
| Source geometry BLK=64, NPT=2 (two batch images per wave, both x4 loads in flight before the stores, half the workgroups) | loss | 0.9595 |
| Earlier session: cold x4 input load issued before the 4 per-channel gathers, one full wait | loss | 0.988 |
| Earlier session: coarsen factor 2 / 4 / 8 on the baseline build | loss | 0.9827 |
| PROBE (not a result): gathers and arithmetic removed, copy at the baseline geometry | probe 88.2 us against 88.3 us | None |
| PROBE: store removed | probe 65.4 us | None |
| PROBE: input load replaced by zeros, gathers + arithmetic + store kept | probe 50.1 us | None |
| PROBE: empty kernel (s_endpgm first) on the baseline grid of 200704 one-wave workgroups | probe 45.1 us | None |

## Session 2026-11-21 07:11

**Harness verdict:** fallback: the named state 7481a6a90f3c22d7 did not verify as a win: parity; outputs within tolerance of the original binary's (largest relative difference 1.08) on 106 cases

## mo_bn_infer: ISA-level analysis (second session)

**Case: memory floor, touch-once.** `in` is read once and `out` written once (205.5 MB each at N=256, C=256, HW4=196). Baseline 88.1 us, 4.66 TB/s, headroom 1.03 to 1.04. The 1.5x target is out of reach; nothing measured in two sessions beat the baseline. Shipped state: `baseline` (amdclang's own build).

### Baseline code (71 instructions, loop-free; unchanged from the first session's description)
Grid (cdiv(C*HW4, 64), N), block 64: one wave per workgroup, 16 B per lane, 1 KB contiguous per wave, 200704 workgroups. Entry: `s_load_dwordx4`, per-lane division tid / hw4, bounds test into EXEC. Body: 3 scalar loads, 4 `global_load_dword` gathers, 1 `global_load_dwordx4`, `vmcnt(1)`, `v_rsq_f32`, 2 `v_pk_add_f32`, 2 `v_pk_mul_f32`, `vmcnt(0)`, 2 `v_pk_fma_f32`, 1 `global_store_dwordx4`.

### Time split (first session's probes, not re-measured)
Full 88.3 us; copy at the same geometry 88.2 us; no store 65.4 us; no input load 50.1 us; empty kernel on the same grid 45.1 us. Gathers, division and arithmetic: 0 us.

### Opportunities measured this session (60 pairs each; none near a win)
| What | Expected | Measured | Verdict |
|---|---|---|---|
| 512 B per wave (block 32, 401408 workgroups) | untested in session 1; 0.87 on rb_scal | 423cb9304444a6c1: 0.846 (0.840..0.848), 3.93 TB/s | loss |
| 2 waves per workgroup by relaunch (block 128) | between 1.0 and 0.969 | eeb0d5e170b45609: launch failure 719 | not timed |
| Two consecutive 1 KB tiles per wave, 10 loads in flight, then 2 stores (half the waves) | half of the 25 us dispatch at best; 0.97 in the copy study | 38fa0bcf52e54dd7: 0.942 (0.937..0.955) | loss |
| Wave-uniform fast path with 4 `s_load_dword` and scalar operands | 0 us by probe | d863fb176d93a338: 0.976 (0.970..0.991) | parity, leaning loss |
| All kernarg loads at entry, one `lgkmcnt(0)` | under 1 % | cfa1ef93f7483414: 1.0005 (0.987..1.009) | parity |

With session 1 (x2 loads 0.994, load first 0.988, coarsen 2/4/8 0.983/0.905/0.859, block 256 0.969, two images per wave 0.960, grid swapped 0.813), eleven candidates of different kinds are at or below parity. The geometry is bracketed on both sides: fewer bytes per wave (0.85) and more bytes per wave (0.94 to 0.98) both lose.

### Differences from amdclang's code
None: the shipped state is amdclang's build. `equivalent(baseline)` against `ref`: within tolerance on all 106 cases, not bit-identical (4 cases identical; the restructured source uses `v_rsq_f32` and packed fma; largest relative difference 1.08 on large_exponent inputs, accepted by the manifest's tolerance rule).

### Untested
- 32 B per lane with a tail path for odd HW4: same bytes per wave as the two-tile state (0.942), so expected to lose.
- Block 128 from a source rebuild (the relaunch failed on the launch bound); block 256 already measured 0.969.
- Nothing that touches fewer bytes exists for this kernel: every input element is needed once and every output element written once.

### Tried

| what | outcome | speedup |
|---|---|---|
| Block 32 at the machine level (tid shift 6 -> 5, relaunch grid cdiv(C*HW4,32) x N, block 32): 512 B per half-filled wave, twice the waves | loss | 0.8455 |
| Block 128 at the machine level (tid shift 7, relaunch block 128: 2 waves per workgroup) | refused: hipModuleLaunchKernel 719 unspecified launch failure (not timed) | None |
| Hand-written body: two consecutive 1 KB tiles per wave (tid and tid+64, separate division and EXEC mask per tile), 8 gathers + 2 x4 input loads in flight, then two stores; half the workgroups | loss | 0.9422 |
| Wave-uniform fast path: v_readfirstlane + v_cmp_eq over the channel index, 4 s_load_dword with SGPR offset instead of 4 per-lane gathers, scalar operands in v_subrev_f32 / v_fma_f32; original body as slow path | parity (CI 0.970..0.991, leaning loss) | 0.9755 |
| All four kernarg s_loads issued at entry with one lgkmcnt(0) wait instead of a second scalar round trip after the bounds branch | parity | 1.0005 |
| A/A control of the baseline | control | 1.0034 |
