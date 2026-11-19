# Progress

Newest entries first. Each entry: what was built or fixed, measured numbers, what is open.

## Status

| Milestone | Issue | State |
|---|---|---|
| M0 Bootstrap | #2 | PR #14 open |
| M1 Measure: runtime, battery, timing | #3 | PR #16 open |
| M2 Corpus and amdclang baselines | #4 | PR #17 open |
| M3 Own the assembly: ISA table and `mir` | #5 | PR #18 open |
| M4 Static safety | #6 | PR open |
| M5 The agent loop on assembly | #9 | open |
| M6 Tensor programs in, binaries out | #10 | open |
| M7 GEMM on MFMA | #11 | open |
| M8 Backend passes for imported code | #8 | open |
| M9 Campaigns and report | #13 | open |
| Stretch: machine-model calibration, attention | #7, #12 | not scheduled |

## Log

### 2026-11-19 — M4: static safety (#6)
- `agc/mir/analysis.py`: instruction classification and def/use from the ISA table (explicit
  and implicit operands, accumulating destinations, EXEC masking), CFG, liveness (masked vector
  writes do not kill by default), reads of undefined registers.
- `agc/mir/waitcnt.py`: forward dataflow over `vmcnt` / `lgkmcnt` / `expcnt`: in-order counters,
  out-of-order scalar loads, stores as events, direct-to-LDS loads, barriers, joins.
- `agc/mir/hazards.py` + `hazards` / `mfma` tables in `gfx950.yaml`: 17 wait-state rules and the
  MFMA rules (pass counts, XDL / SGEMM / DGEMM classes, results read as A/B or C, by VALU or
  memory, overwritten results and accumulators), from LLVM's GCNHazardRecognizer for gfx950.
- `agc/mir/check.py`: `static_check` = verifier + contract (descriptor / metadata cover the
  code) + undefined reads + waitcnt + hazards + encode with decode cross-check. CLI `agc static`.
- amdclang output: zero error findings on all 12 corpus kernels.
- Mutation suite over the corpus, 844 mutants:

| Class | Caught |
|---|---|
| `s_waitcnt` deleted | 176 / 176 |
| wait counter raised by one or dropped | 179 / 179 |
| `s_nop` deleted or shortened | 29 / 29 |
| register in the wrong file (illegal result) | 134 / 134 |
| register widened | 178 / 178 |
| descriptor / metadata understates registers | 48 / 48 |
| source replaced by a register nothing writes | 56 / 56 |
| register in the wrong file (still a legal instruction) | 4 / 44 |

  Every statically decidable mutant is caught (800 / 800); overall 804 / 844 = 95.3 %. The 40
  misses are legal instructions that compute something else, which is the battery's job.
- MFMA rules validated on `tests/fixtures/mfma_probe.hip` (amdclang's MFMA code, 9 MFMAs): all
  17 `s_nop` deletions / shortenings are caught, so the wait-state numbers match the compiler.
- Bug found by the mutation suite: amdclang prints no label for the fall-through of a
  conditional branch, so a wait required on one path looked redundant. Blocks are now split
  at branches when parsing (labels emit no bytes; `.text` stays identical).
- Divergence found: ROCm LLVM (amd-staging) requires wait states when two different MFMAs share
  an accumulator (6 for a 4-pass XDL writer); the installed amdclang 23.0.0git emits none
  (`mfma_feed` in the probe). agc keeps the stricter rule.
- amdclang reads registers that are undefined on some path (the unused half of a 64-bit
  operand, a loop-carried mask), so that finding is a warning; a register nothing writes is
  an error.
- Open: permlane, `s_setreg` / `s_getreg` and `movrel` hazards are not modelled (using them is
  a finding); the stricter MFMA rule is not yet confirmed on hardware.

### 2026-11-19 — M3: ISA table and `mir` (#5)
- `scripts/gen_isa.py` compiles AMD's `amdgpu_isa_cdna4.xml` into `agc/isa/cdna4.json.gz`
  (1240 instructions, 33 encodings with bit layouts, 35 operand types; 69 KB, deterministic).
  `agc.isa`: mnemonic resolution with LLVM's `_e32/_e64/_dpp/_sdwa` forms, operand specs
  (explicit and implicit, in/out), operand-type classes, and a decoder driven only by the table.
- `agc/mir`: IR (registers, immediates kept as written, labels, counters, modifiers, blocks with
  alignment), parser/printer for the amdclang dialect, kernel descriptor and metadata as data,
  `abi.make_kernel` (descriptor, metadata and argument layout derived from code + argument
  list), `emit.build` (`llvm-mc` + `ld.lld`), verifier against the ISA table.
- All 12 corpus kernels import, verify with zero findings and re-emit with a byte-identical
  `.text`, an identical kernel descriptor (except the code offset) and identical metadata.
  Register counts and `accum_offset` recomputed from the instruction stream equal amdclang's.
- Cross-check independent of LLVM: the emitted `.text` decoded from the specification gives
  the module's instruction sequence for every kernel (alignment `s_nop`s allowed).
- Verifier and `llvm-mc` agree on 38 legal and 22 illegal instructions (wrong class, wrong
  width, literal where none is allowed, two literals, offsets out of range, bad counters).
- A kernel written by hand in `mir` (`tests/mir/axpy_hand.s`, no HIP, no hidden arguments)
  passes the battery 49/49 and is at parity with amdclang: 1.009x, CI [1.002, 1.013].
- Protocol change: a paired result is `win` / `loss` only when the whole CI lies beyond a 1 %
  noise floor. The hand-written AXPY would otherwise have been reported as a 0.9 % win, which
  is inside the A/A band (0.992 to 1.009) measured in M1.
- Learned: on gfx950 the bf16 MFMA sources are 4 registers (`v[0:3]`), as the XML says; with a
  scalar base register the FLAT address operand is a 32-bit offset; amdclang pads after the
  last kernel with `0xBF800000` and aligns loop headers with `.p2align 5, , 4`.
- Open: MUBUF/MTBUF syntax is not modelled (rejected); modules with non-kernel functions are
  rejected at import.

### 2026-11-19 — M2: corpus and amdclang baselines (#4)
- 12 HIP kernels with manifests and NumPy / einsum references; every one passes the full
  battery (49 to 105 cases each, including shape variants of every dynamic symbol).
- Baselines in `tests/baselines/amdclang-gfx950.json` (`make baseline`), `amdclang -O3`,
  protocol `agc-timing-amd-1`, cache flushed:

| Kernel | Bench shape | Median ms | VGPR / SGPR | LDS bytes | Instructions | A/A |
|---|---|---|---|---|---|---|
| `axpy` | N=67108864 | 0.183 | 6 / 12 | 0 | 22 | 0.999 |
| `cast_bf16` | N=67108864 | 0.159 | 6 / 11 | 0 | 26 | 1.002 |
| `gelu` | N=67108864 | 0.191 | 8 / 12 | 0 | 70 | 1.000 |
| `gemm_naive` | M=2048 × N=2048 × K=2048 | 4.046 | 12 / 18 | 0 | 63 | 1.000 |
| `gemm_tiled` | M=2048 × N=2048 × K=2048 | 0.909 | 46 / 20 | 2048 | 121 | 1.000 |
| `layernorm` | rows=32768 × cols=4096 | 0.452 | 14 / 46 | 1024 | 313 | 1.000 |
| `matvec` | rows=16384 × cols=4096 | 0.560 | 6 / 16 | 0 | 39 | 1.002 |
| `rmsnorm` | rows=32768 × cols=4096 | 0.365 | 10 / 27 | 1024 | 196 | 1.000 |
| `row_argmax` | rows=32768 × cols=4096 | 0.199 | 7 / 19 | 2048 | 184 | 1.002 |
| `row_sum` | rows=32768 × cols=4096 | 0.188 | 7 / 17 | 1024 | 129 | 1.002 |
| `softmax` | rows=32768 × cols=4096 | 0.433 | 16 / 41 | 1024 | 384 | 0.999 |
| `transpose` | rows=4096 × cols=8192 | 0.123 | 8 / 14 | 0 | 35 | 0.998 |

- Every kernel is at the hardware occupancy limit (8 waves per SIMD): none is register-limited.
- amdclang uses no MFMA and no wide (`dwordx4`) loads anywhere in the corpus; the rowwise
  kernels are 129 to 384 instructions, mostly the LDS tree reduction.
- Build cache keys now include the contents of quoted includes.
- Open: no library baselines yet (hipBLASLt for GEMM comes with M7).

### 2026-11-19 — M1: runtime, battery, timing (#3)
- Built: `gfx950.yaml` + occupancy; HIP module API through ctypes; amdclang / assemble / link /
  inspect wrappers with toolchain identity in cache keys; manifest; per-device executor
  (8 locks, `auto` device choice, interactive before batch) with one worker process per job;
  battery (6 distributions, hidden seeds, shape variants, poisoning, rtol/atol/cond);
  timing `agc-timing-amd-1` and paired interleaved comparison; CLI `agc build|check|bench|info`.
- AXPY (amdclang, 6 VGPRs): battery 49/49 cases; 0.17 ms at N = 2^26 (about 4.7 TB/s),
  event time within 10 us of host wall-clock, linear in N from 2^22 to 2^28.
- A/A control (same code object twice, 60 pairs) on six devices: speedup 0.992 to 1.009,
  every 95 % CI contains 1.0 and lies within ±2 %. A deliberately slower kernel is reported
  as `loss`, the reverse as `win`; a wrong candidate is refused before timing.
- Found on the way: amdclang contracts `a*x+y` to `v_fmac_f32`, so AXPY needs the `cond`
  allowance under cancellation (rtol alone fails the `large_exponent` distribution).
- `amdclang`'s own `-S` output re-assembled through `llvm-mc` + `ld.lld` gives a
  byte-identical `.text` and identical metadata (the basis of M3's round-trip).
- Open: kernels under about 50 us are dominated by launch overhead (18 to 28 us at N = 2^22),
  so manifests carry `bench_shapes`; clocks float between 500 / 1012 / 2400 MHz levels on the
  VFs and are only recorded; GPU tests still run serially.

### 2026-11-19 — Roadmap revision
- Reordered into milestones M0 to M9 with measurable exits: agent loop (M5) before
  automatic passes (M8), generators (M6, M7) before passes; interpreter, standalone
  calibration, attention, FP8, profiler and recipe promotion moved to stretch.

### 2026-11-19 — P0 bootstrap
- Repo skeleton, design, roadmap, workflow skill, CI. Host: 8 × MI355X VF, ROCm 7.14.
- Feasibility: amdclang `-S` output for `gfx950` (code object v6) is the import format.
