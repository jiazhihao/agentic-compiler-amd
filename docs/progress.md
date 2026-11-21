# Progress

Newest entries first. Each entry: what was built or fixed, measured numbers, what is open.

## Status

| Milestone | Issue | State |
|---|---|---|
| M0 Bootstrap | #2 | merged (#14) |
| M1 Measure: runtime, battery, timing | #3 | merged (#16) |
| M2 Corpus and amdclang baselines | #4 | merged (#17) |
| M3 Own the assembly: ISA table and `mir` | #5 | merged (#18) |
| M4 Static safety | #6 | merged (#19) |
| M5 The agent loop on assembly | #9 | PR #21 open |
| M6 Tensor programs in, binaries out | #10 | PR #22 open |
| M7 GEMM on MFMA | #11 | PR #24 open |
| M8 Backend passes for imported code | #8 | PR #25 open |
| M9 Campaigns and report | #13 | PR #26 open |
| Codex review fixes | #27 | PR open |
| Stretch: machine-model calibration, attention, LDS GEMM | #7, #12, #23 | not scheduled |
| Phase 2 roadmap: agc's own lowering | #77 | PR #78 open |
| M11 Tracer bullet: HIP to the GPU, own path | #79 | PR #80 open |
| M12 Control flow, loops, loop decisions | #81 | PR #82 open |
| M13 Shared memory, barriers, division, reductions | #83 | PR open |

## Log

### 2026-11-21 — M13: shared memory, barriers, division, the reduction decision (#83)
- **What.** Frontend: `__shared__` arrays, `__syncthreads`, captureless lambdas passed to inlined templates
  (`block_reduce(red, acc, [](float a, float b) { return a + b; })`), integer `/` and `%`. `kir` / `wir`: LDS
  pointers, `shared` / `region` (the LDS size in the descriptor is derived), `barrier`, LDS accesses
  (`ds_read_*`, `ds_write_*`, wide forms), `wgreduce` / `lane.reduce`. Division is expanded in `kir`: shifts,
  a multiply-high by a precomputed reciprocal, or the floating-point reciprocal estimate with one Newton step
  and two corrections (LLVM's `expandDivRem32`); a 64-bit remainder of a 32-bit value the way amdclang's own
  code does it. Tree reductions through shared memory are recognized (`agc/kir/idioms.py`).
- **Decisions.** `reduce.form` (`lds_tree` / `dpp`), `order.loads` (`first` / `as_written`). `loop.inflight`
  now defaults to `first`: amdclang issues a block's loads before the arithmetic too, and without that
  `gemm_tiled` waited once per LDS read. `loop.unroll` is offered when the counter starts at a thread's index.
- **Safety gates** on `wir`: an LDS load of a slot the lane did not store, with no barrier since a store to the
  region; a barrier in a loop each lane leaves on its own. Deleting each of the 13 barriers of three lowerings:
  11 caught. Not caught: a barrier nothing follows, and the barrier that keeps the next tile's stores behind
  this tile's reads in `gemm_tiled` (a write after a read, not modelled).
- **Measured** (`tests/baselines/own-gfx950.json`, paired against amdclang -O3, full battery on every row):

| Kernel | Default plan (95 % CI) | Bit-identical | Instructions (own / amdclang) | Decisions | With them (95 % CI) |
|---|---|---|---|---|---|
| `row_sum` | 0.955 (0.952 to 0.957) | yes | 156 / 128 | `loop.unroll` 16 | **1.291** (1.279 to 1.303), bit-identical |
| `row_sum` | | | | `reduce.form` dpp | 0.986 (0.981 to 0.992), within tolerance |
| `row_sum` | | | | `reduce.form` dpp, `loop.unroll` 16 | **1.296** (1.285 to 1.308), within tolerance |
| `gemm_tiled` | 0.757 (0.754 to 0.760) | no (yes with `fp.contract` off) | 128 / 120 | `loop.unroll` 4, 8, 16 | 0.76, 0.76, 0.63: losses |
| `mo_rope_fwd` | 0.801 (0.797 to 0.804) | yes | 70 / 68 | none | |

  15 of 50 kernels pass through the own path (14 bit-identical with the default plan); geomean of the default
  plan 0.942. `tests/own/divmod` (division by a variable and by constants, signed, unsigned, 64-bit) passes the
  battery: the reciprocal method is exact with the hardware's `v_rcp_f32`.
- **Against the exit.** `row_sum` at 1.2x: reached (1.29x), but by `loop.unroll`, bit-identical, the same gain
  the phase-1 pass had. The DPP reduction itself is worth 3 % there (0.955 to 0.986): the time is in the column
  loop, where each lane waits for one load per trip, not in the eight barrier rounds. Default plan at 0.90 or
  better: missed on `gemm_tiled` (0.76), `mo_rope_fwd` (0.80) and still `rb_ger` (0.80). `row_argmax` (records)
  and the `mir` interpreter are moved to M15 and M16.
- **Found.** amdclang does not fuse the multiply and the add in `gemm_tiled` (its vectorizer forms
  `v_pk_mul_f32` first), so `fp.contract: on` is not always what amdclang does; `off` is bit-identical there.
  The workgroup's tree reduction is a small part of `row_sum`'s time, contrary to what the roadmap assumed.
- **Open.** `gemm_tiled` and `mo_rope_fwd` are 20 % to 24 % behind with no decision that closes it (not
  analysed; M16). Records, atomics, lane shuffles, local arrays (M15). The gate does not model a store that
  overwrites what another wave still reads. The GPU suite was run for the own-path tests only.

### 2026-11-21 — M12: control flow, loops, and the first decisions that beat amdclang (#81)
- **What.** Frontend: early `return`, `break`, `continue`, `do`, a `return` from a loop of an inlined
  function, all as conditions in SSA (what follows a statement that may leave runs where it did not; a loop
  carries the flag). `kir`: condition simplification (inverse compares, De Morgan, selects), LICM, CSE,
  reassociation of constant index offsets, counted-loop recognition and unrolling (`agc/kir/loops.py`).
  Wave lowering: a loop on a uniform integer comparison is a counted jump; any other loop runs under a mask
  each lane drops out of; a carried value stays in an SGPR while its initial and next values are uniform.
  Selection: loops test at the bottom, a next value is computed straight into the carried register,
  scalar loads (`s_load_dword*`) for uniform addresses, widening and 64-bit multiplies, merged values as one
  register written on each side of a region.
- **Decisions added.** `loop.unroll` (1, 2, 4, 8, 16; also when each thread has its own bound),
  `loop.inflight` (`as_written` / `first`), `load.uniform` (`scalar` / `vector`), `access.width` up to 16 for
  scalar loads. Unrolling keeps the operations in source order, so the results are bit-identical; `first`
  moves a trip's loads (and their address arithmetic) ahead of the arithmetic, unless a store in between may
  overlap; waits are then derived at the first use, so one wait covers them.
- **Measured** (`tests/baselines/own-gfx950.json`; paired against amdclang -O3 on the source as shipped; every
  row passed the full battery and is bit-identical to amdclang's binary):

| Kernel | Default plan (95 % CI) | Instructions (own / amdclang) | Best loop decisions | With them (95 % CI) |
|---|---|---|---|---|
| `matvec` | 0.976 (0.975 to 0.978) | 37 / 38 | `loop.unroll` 16, `loop.inflight` first | **2.773** (2.763 to 2.782) |
| `gemm_naive` | 0.905 (0.904 to 0.905) | 50 / 62 | `loop.unroll` 16, `loop.inflight` first | **2.157** (2.150 to 2.164) |
| `rb_ger` | 0.792 (0.783 to 0.800) | 64 / 100 | `loop.unroll` 4, `loop.inflight` first | **1.042** (1.036 to 1.049) |
| `gemm_bf16` | 1.000 (0.999 to 1.000) | 52 / 53 | none is a win (1.00 at 4, 8, 16) | |
| `transpose` | 0.997 (0.991 to 1.003) | 35 / 34 | no loop | |

  The seven kernels of M11 stay at parity (0.996 to 1.004). 12 of 50 kernels now pass through the own path,
  geomean of the default plan 0.970. The control-flow kernels written for this milestone (`tests/own/`:
  break, continue, do-while, a return inside a counting-down loop of an inlined function) pass the battery.
- **Against the exit.** `matvec` 2.77x (target 2.5x; the pass on imported assembly: 2.79x) and `gemm_naive`
  2.16x (target 2.0x; the pass: 2.19x), by decisions on the own lowering. Default plan at 0.90 or better: met
  on 11 kernels, missed on `rb_ger` (0.79). There amdclang's default already runs two iterations per trip
  (its loop vectorizer emits `v_pk_fma_f32` on two iterations' loads), while agc's default is the loop as
  written; `loop.unroll` 4 gives 1.04x. The default does not imitate amdclang's vectorizer heuristics.
- **Found on the way.** On gfx950 a kernel that asks for more than the x workitem id gets all three packed in
  `v0`, 10 bits each (2-D kernels wrote one row before this was read from amdclang's code). A scalar load
  ignores the low two bits of its offset: the 16-bit `group_size_y` is the high half of the dword at the
  aligned offset. A merged value that one side defines must not be read on the path that skips that side:
  the strict static check refused it, and merges became masked copies into one register.
- **Open.** `gemm_naive`'s default is 9 % behind: amdclang turns the indices into pointer increments (9
  instructions per trip against 13); strength reduction of addresses is M16. `gemm_bf16` does not gain from
  the loop decisions (cause not analysed). `mo_rope_fwd` needs a 64-bit remainder (M13). The loop decisions
  are swept by the recorder and are candidates of `optimize(s, own=True)`, not of the default policy.
  `branch.form` and `loop.bulk` were not built. The GPU suite was run for the own-path tests only.

### 2026-11-21 — M11: tracer bullet, HIP to the GPU with no amdclang code generation (#79)
- **What.** agc's own lowering, end to end. `agc/frontend`: Clang's JSON AST (`-fsyntax-only`, cached) to
  `kir` for a bounded subset (scalar and pointer locals, arithmetic, casts, `if`, `for` / `while` / `do`,
  pointer arithmetic, the HIP builtin variables, inlined functions and template instantiations); every
  unsupported construct is reported with its source location. `agc/kir`: the thread-level IR (structured
  SSA with `if` merges and loop-carried values; text, parser, verifier, NumPy interpreter) and its passes
  (folding, CSE, dead code, constant-trip loops unrolled, fma contraction, no-wrap index widening).
  `agc/wir`: the wave-level IR (`u` / `v` values, `where` / `branch` regions, loads and stores with base,
  index, scale and offset, wide accesses; verifier; an interpreter that also checks every `u` value is
  uniform within a wave). `agc/lower`: wave lowering (uniformity from the selection table's scalar forms),
  redundant-load elimination, adjacent accesses merged, instruction selection from
  `agc/arch/gfx950.isel.yaml` into the existing virtual-register builder, allocator, `fix_waits`,
  `fix_hazards` and `abi.make_kernel`.
- **Decisions.** A compilation returns its plan. Three decisions so far, each with amdclang's behaviour as
  the default: `fp.contract` (kernel), `access.width` (per access group: 4, 2, 1), `branch.skip_empty` (per
  `where`). Session and MCP: `lower(overrides)`, `plan`, `replan` (lower again with some decisions changed;
  the default alternative gives the first state back), `explain`, `ir`.
- **Checks.** On the CPU, with no toolchain (CI): `kir` against the manifest's reference and `wir` against
  `kir` on battery inputs at reduced shapes; the frontend's output is recorded in `tests/kir/`. On the
  device: static check (strict), full battery, `equivalent` against amdclang's binary.
- **Measured** (`scripts/own_path.py` → `tests/baselines/own-gfx950.json`, default plan, paired against
  amdclang -O3 on the source as shipped):

| Kernel | Battery | Bit-identical to amdclang | Speed over amdclang (95 % CI) | Instructions (own / amdclang) |
|---|---|---|---|---|
| `axpy` | 49/49 | yes | 1.007 (0.999 to 1.015) | 22 / 21 |
| `cast_bf16` | 49/49 | yes | 1.002 (0.996 to 1.007) | 24 / 25 |
| `rb_axpy` | 49/49 | yes | 0.996 (0.990 to 1.002) | 42 / 41 |
| `rb_copy` | 49/49 | yes | 1.004 (0.998 to 1.010) | 35 / 30 |
| `rb_rot` | 49/49 | yes | 1.003 (0.990 to 1.015) | 28 / 28 |
| `rb_scal` | 49/49 | yes | 1.000 (0.987 to 1.014) | 38 / 36 |
| `rb_swap` | 49/49 | yes | 1.005 (0.992 to 1.018) | 41 / 36 |

  Seven of 50 kernels pass through the own path, all at parity (geomean 1.002, none below 0.996); the exit
  asked for five at 0.90 or better. Of the other 43, 42 are refused by the frontend (early `return`, arrays,
  records, `__shared__`, math calls, member calls) and one (`transpose`) by the lowering (64-bit multiply).
- **What parity needed.** The first version was at 0.85 to 0.92 on the five rocBLAS kernels. The gap was
  memory instructions, not arithmetic: amdclang reads `x[i]` and `x[i + 1]` with one `dwordx2` load (one
  round trip to memory instead of two), and reads a value once where the source reads it twice. Merging
  adjacent accesses needed `extend(i + 1) = extend(i) + 1`, which holds because `i` is even (known bits) or
  signed (`nsw`). Arguments are assumed not to overlap each other: every tensor of a manifest is its own
  allocation (D17), which amdclang only knows from `__restrict__`.
- **Open.** Loops with a runtime trip count are parsed and interpreted but not lowered (M12). The selection
  table covers 32-bit integer and float arithmetic, 64-bit add / shift / compare, and conversions; no
  64-bit multiply, no division, no LDS, no math functions. Each kernel argument is loaded on its own at
  entry (amdclang groups them and loads late; parity on these kernels). A uniform condition computed per
  lane still becomes a `where` region, not a branch. The GPU test suite was run for the own-path tests only.

### 2026-11-21 — Roadmap, phase 2: agc's own lowering from HIP to assembly (#77)
- **What.** Roadmap M11 to M21 (`docs/roadmap.md`, issue #77) and design decisions D3', D9', D12
  to D18: Clang as parser only, `kir` (thread level) and `wir` (wave-level schedule IR) above
  `mir`, lowering as recorded decisions with alternatives, replanning as backtracking, gates with
  site-addressed findings, a cost model, the evolution loop, a matched experiment against raw
  `mir` edits. Modelled on CAKE (arXiv 2608.12629, read in full); the difference is that agc
  lowers to the machine's assembly, not to PTX.
- **Measured.** Clang's JSON AST for `axpy.hip` (`-fsyntax-only -Xclang -ast-dump=json`, filtered
  to the entry): 0.6 s, 150 KB. Nothing else was run; this entry is a plan.
- **Open.** Everything in it. The milestone sizes (about 30 k lines in total) and the exit numbers
  are estimates; the kernels named as candidates for M11 are not yet confirmed by a frontend.

### 2026-11-23 — GEMM with LDS-shared operands; FP8 GEMM (#23, #75)
- **LDS-shared GEMM (#23).** `gemm_mfma` got `share`: four waves per workgroup compute a 2x2 block of
  quarters and share the operand halves through LDS, so a workgroup loads each operand element once.
  `share=1`: each wave keeps one half and reads the other from LDS, one barrier per K-step. `share=2`:
  both halves through LDS; wave w loads half w in row pieces (16 rows x 64 contiguous bytes per load),
  one barrier per macro step, the next macro step's loads in flight. All 17 variants pass the full
  battery. bf16 against hipBLASLt (time ratio, before in brackets): 4096^3 1.55 (2.65), 818 TFLOP/s;
  2048 x 8192 x 4096 1.53; 8192 x 2048 x 4096 1.61; 2048^3 1.43 (2.5). The issue's target (within
  1.5x on at least one shape) is met on the small shape.
- **What bounds it, measured.** Still the loads from memory (about 130 of 187 us at 4096^3 in
  `share=1`). They cost per load instruction (FP8 `dwordx2` loads took as long as bf16 `dwordx4` loads
  of twice the bytes) and per cache line touched (rows per load 32 / 16 / 2: 186 / 160 / 138 us). LDS
  reads of the same volume cost about 5 %, provided one read covers all 64 LDS banks: a row-major LDS
  layout cost 120 us. Loads straight into LDS (`share=3`) lose (0.200 against 0.172 ms): the barrier
  has to wait for them. Loads two or three macro steps ahead: nothing.
- **FP8 GEMM (#75).** New corpus kernel `gemm_fp8` (E4M3 inputs, f32 result; amdclang baseline with a
  software decode). The template takes `e4m3` and `e5m2`; `wide=1` uses gfx950's 32x32x64 FP8 MFMA
  (half the MFMA passes). Loads are always 16 bytes per lane. Against hipBLASLt's FP8 path: 4096^3
  1.33 (1462 TFLOP/s), 2048 x 8192 x 4096 1.28, 8192 x 2048 x 4096 1.34, 2048^3 1.17 (679 TFLOP/s).
  E5M2 passes the battery with both MFMAs (GPU test, no recorded timing).
- **FP8 precision.** The FP8 MFMAs lose part of products far below the largest one of a group: worst
  measured error 1.4e-4 of the sum of magnitudes (amdclang's software decode: 4e-7). `gemm_fp8`'s
  tolerance is `cond` 2.5e-4 (bf16: 2e-5). This is a decision about the contract, recorded in the manifest.
- **Open.** bf16 is still 1.5x to 1.6x behind hipBLASLt on the large shapes and FP8 1.2x to 1.3x; what
  hipBLASLt does differently is not known. The remaining idea, deeper overlap of direct-to-LDS loads,
  needs the static checker to tell LDS buffers apart. Timings are single-allocation `bench` medians
  and paired timings against amdclang; the library is timed in its own process.

### 2026-11-22 — placement-aware timing, knowledge base, non-temporal loads, attention template, fusion (#66, #67, #71, #73)
- **Timing (#66).** The time of a memory-bound kernel depends on where its tensors were allocated (up to
  6 %, differently for each binary, same virtual addresses). On `rb_axpy` one candidate measured 0.97 to
  1.05 across allocations. Paired timings now spread the pairs over several allocations (10 pairs each)
  with the CI over the allocations. All 19 session recipes were re-verified under it: 18 hold
  (`fa_attention` 2.105, `fa_attention_causal` 1.981, `mla_decode` 1.563, `attn_decode` 1.552,
  `vl_moe_align` 1.550, `fi_merge_states` 1.122, `rb_scal` 1.122, the rest 1.015 to 1.07);
  `mo_rope_fwd` is parity (1.002) and its recipe is removed.
- **Knowledge base (#67).** `.claude/skills/agc-notes/kb/`: `OPTIMIZATIONS.md` (catalog by technique,
  hand-written), `RECIPES.md` and `INDEX.md` (generated by `scripts/kb.py` from the records and the
  236 per-kernel entries), tool `kb(query)`.
- **Non-temporal loads (#67).** Pass `stream_loads` (`sc0 sc1 nt` on every vector load, bit-identical), in
  the default policy alone and on top of the best other win. With the caches flushed before every launch
  (the protocol's default) it wins on 23 of 36 kernels, 1.03x to 1.89x. With the caches as the previous
  launch left them, 13 of those stay wins (1.04x to 1.20x), 3 are parity and 7 are losses (down to 0.90).
  Cause, measured on `fi_silu_and_mul`: the baseline is 96.8 us after a flush and 60.8 us warm; a normal
  load evicts what the flush left in the caches, a non-temporal one does not. Every such result carries
  its warm control (`bench_warm`, `chosen.warm`); the tables give both views.
- **Attention template (#71).** `attention_mfma` compiles `softmax(scale Q K^T) V` from a tair program to
  MFMA code (16 queries x 16 keys per tile, online softmax, waves sharing the key tiles, next tile's loads
  in flight). The default policy picks it on `fa_attention` at 1.949 (1.942 to 1.956) with no agent
  session; the hand-written recipe is 2.105. Row width 128 passes the battery. `fix_waits` no longer asks
  for more than the wait counter can name.
- **Fusion (#73).** `agc.tair.fuse` composes two tensor programs into one kernel. Fused against the two
  fastest separate kernels (medians, not paired; flushed / warm caches): `rmsnorm` then `gelu` 1.78 / 1.74,
  `layernorm` then `gelu` 1.63 / 1.58, `gelu` then `cast_bf16` 2.14 / 2.25. Full battery passed.
- **Totals on the LLM benchmark** (`scripts/sessions.py table`): with flushed caches 31 of 36 kernels with
  a verified gain, geomean 1.276; counting `stream_loads` results at their warm-cache value, 23 of 36 and
  geomean 1.120 (before this entry: 20 of 36, 1.098, measured on single allocations).
- **Open.** Which cache state represents a real pipeline is not settled: a kernel usually follows another
  kernel's large write, but often of its own input. GEMM with LDS-shared operands (#23) and FP8 GEMM not
  started. The causal attention variant is not covered by the template. Fusion is compared as a ratio of
  medians of separate launches (no pipeline job in the harness). The corpus records predate the
  placement-aware timing. The GPU pytest suite was not run as a whole.

### 2026-11-21 — ISA-level campaign over the kernels without a gain (#64)
- **What ran.** For each of the 21 kernels without a verified gain: analysis-first sessions
  (instruction mix, time split from probes, a list of ISA-level opportunities, each measured as
  its own verified state), up to three per kernel, each continuing from the kernel's analysis so
  far: 44 sessions. Analyses in `docs/kernels/`, 236 knowledge-base entries in
  `.claude/skills/agc-notes/kb/`, the cross-kernel summary in `kb/PATTERNS.md`.
- **Result.** 1.5x reached on one of the 21: `vl_moe_align` 1.546 (1.539 to 1.555), bit-identical
  (idle workgroups prefetch for the counting one, 16 LDS slots per histogram bin so `ds_add_u32`
  lanes do not collide, software-pipelined loads). Four more with a small verified gain:
  `mo_adam` 1.025, `rb_dot` 1.023, `rb_nrm2` 1.022, `fi_silu_and_mul` 1.021. The other 16 stay
  fallbacks: all are touch-once kernels at the memory floor (headroom 0.94 to 1.12), with 4 to 15
  timed machine-level candidates each at parity or loss (`kda_step`: two). Now 20 of 36 kernels have a verified
  agc gain over the strongest amdclang build, five at or above 1.5x, geomean 1.098.
- **Correctness.** The harness verification now runs the original binary (amdclang -O3, source as
  shipped) and the candidate on the same inputs and compares the outputs. All 55 shipped states
  (baselines, recipes, policy results) are within tolerance of the original, 14 bit-identical; the
  rest differ only where the baseline itself is a `-ffast-math` build
  (`tests/baselines/llm-equivalence-gfx950.json`).
- **Pass.** `throttle` (LDS reservation limiting workgroups per compute unit), from the `rb_dot`
  and `rb_nrm2` sessions; in the default policy at 4 per CU. Swept over all 36 kernels: it wins
  on those two only (1.026, 1.032), is parity on the other multi-wave kernels and loses 1.3x to
  10x on one-wave workgroups.
- **Open.** The 1.5x target is not met on 20 of the 21 kernels and, by these measurements, cannot
  be at the ISA level for touch-once kernels. The baseline's time is bimodal on the long
  elementwise kernels (cause unknown), which made several 120-pair wins vanish at 240 pairs.
  `kda_step` had only two machine-level candidates timed. The policy record was rerun for
  `rb_dot` and `rb_nrm2` only. GPU pytest suite not run in this PR.

### 2026-11-21 — second round of sessions against the strongest amdclang builds (#62)
- **Sessions.** Every one of the 36 kernels had a session against its stronger baseline, and
  `mla_decode`, `fa_attention`, `kda_step` a third one. A session's own source rewrite is now
  credited to amdclang: four baselines were strengthened that way (`rb_gemvn`, `kda_step`,
  `mo_active_fwd`, `mo_rope_fwd`).
- **Result.** 15 of 36 kernels have a verified agc gain over the strongest amdclang build
  (policy or session), geomean 1.08 with fallbacks at 1.0 (`scripts/sessions.py table`). At or
  above 1.5x: `fa_attention` 2.09x (rewritten on `v_mfma_f32_16x16x4_f32`), `fa_attention_causal`
  1.99x, `mla_decode` 1.57x, `attn_decode` 1.55x. These are the kernels that re-read their
  inputs; the gains are loads in flight, scalar loads of wave-uniform rows, fewer re-reads, MFMA.
  Below: `rb_scal` 1.12x, `fi_merge_states` 1.11x, `fi_rmsnorm` 1.08x, eight between 1.01x and
  1.06x. The 21 kernels without a gain touch every element once; most of their sessions measured
  machine-level rewrites at parity and report the kernel at the memory floor. 1.5x on those is
  not reachable by moving the same bytes.
- **Passes, from the sessions' friction.** `unroll_loads` handles amdclang's exec-mask loops
  (per-lane counter, guarded bulk loop) and counters that step by more than one: `row_sum`
  1.29x, `rmsnorm` 1.25x, `layernorm` 1.17x from the pass alone, bit-identical; parity on the
  three LLM baseline loops it applies to. `coarsen` accepts scratch spills, offset copies of the
  kernarg pointer and workgroup-uniform early exits. `fix_waits(rewrite)` re-derives all waits.
- **Tools.** `%rep` / `%for` in edit text, labels in edit text, block replace, registers dead
  across a block, transform parameters and compare results in `list_states`, `source(like=)`
  inherits flags and defines, short edit echoes; checker: vcc/exec halves as scalars, a scalar no
  path has written is an error, nearest mnemonic, constant-bus hint.
- **Open.** `unroll_loads` on kernels with indexed registers, loops with stores or data exits;
  cooperation of workgroups on one output (`vl_moe_align`); LDS size from an edit; paired probes;
  battery shapes that leave fast paths unexercised (`attn_decode`, `mo_adam`, `kda_step`,
  `fi_rmsnorm`). The full GPU test suite has not been run on this branch.

### 2026-11-20 — stronger baseline: the strongest amdclang build per kernel (#62)
- **What changed.** A manifest names a `baseline` (source, flags, defines, launch); the session
  imports it as state `baseline` and `bench`, the default policy and the harness measure against
  it. `ref` stays amdclang -O3 on the source as shipped. `scripts/strong_baseline.py` chooses the
  baseline per kernel among the shipped source and the round-1 restructured source, each with and
  without `-ffast-math`; every candidate passes the full battery and the chosen one is confirmed
  by two valid 240-pair timings. Record: `tests/baselines/llm-strong-gfx950.json`.
- **Baselines.** 26 of 36 kernels have a baseline stronger than -O3 on the shipped source: 24
  from a restructured source (12 of them also with `-ffast-math`), 2 from `-ffast-math` alone.
  The largest: `moe_gate_topk` 18.3x, `attn_decode` 7.4x, `vl_moe_align` 5.8x, `fa_attention`
  3.9x, `fa_attention_causal` 2.2x, `fi_rope` 2.2x, `rb_gemvn` 2.2x.
- **agc against the stronger baseline.** Round-1 recipes replayed: 23 are parity, identical to
  the baseline or slower than it (they were amdclang's code) and are dropped; `mla_decode` stays
  a win, **1.486x** (1.485 to 1.487) from its `mir` edits. Default policy: 7 wins (`coarsen`,
  1.04x to 1.08x), 29 fallbacks. Together 8 of 36 kernels with a verified agc gain, geomean
  1.022 with fallbacks at 1.0; the geomean of the best build over -O3 on the shipped source is
  1.536, most of it amdclang's.
- **Harness.** A session's own `source` state that beats the baseline is a baseline candidate
  (outcome `baseline`, not a win); the final state must beat that build too. The prompt targets
  machine-level gain. `agc replay --update` re-verifies recipes against the current baseline.
- **Open.** Second round of sessions against the new baselines. The 10 kernels that never had a
  session have had no source-level search, so their baseline is only -O3 or `-ffast-math`.

### 2026-11-20 — baseline audit of the LLM benchmark (#29, #34)
- **Attribution.** For every recorded session recipe the source-rewritten state was timed on its
  own. 22 of 23 recipes are amdclang's compilation of the rewritten source with no machine-level
  work; their speedups are source restructurings that amdclang delivers by itself. Only
  `mla_decode` has a machine-level part: 1.70x from the rewritten source, 2.54x after the `mir`
  edits (1.49x from agc's own level). Recipes and the session table now carry
  `amdclang on the rewritten source` and `machine-level gain`; the harness measures both when
  it records a recipe.
- **Flags** (`tests/baselines/llm-flags-gfx950.json`, unmodified sources, 120 pairs against
  `-O3`): `-ffast-math` gives `fi_rope` 1.98x, `fa_attention_causal` 1.44x, `fa_attention`
  1.35x, `rb_gemvt` 1.19x, `mo_glu_fwd` 1.08x, `mla_decode` 1.08x, `moe_gate_topk` 1.06x,
  `mo_t5_layernorm` 1.05x, `fi_rmsnorm` 1.03x; it loses 2 % to 4 % on `attn_decode`, `kda_step`,
  `mo_prelu_bwd`. `-funroll-loops` produces identical code everywhere; `-O2` is identical or
  parity. So `fi_rope`'s 2.1x session and `rb_gemvt`'s 1.23x are almost entirely fast-math.
- **Ports.** `attn_decode`, `fa_attention*`, `mla_decode`, `kda_step` and `moe_gate_topk` are
  simplified ports written for this benchmark; the optimized upstream kernels (FlashInfer's
  decode attention, vLLM's top-k template) were not extracted. Their baselines are weaker than
  what the libraries ship, and the largest session speedups (18x, 7.4x, 3.9x) are on them.
- **Measurement.** Timings are paired, verified at the bench shapes before and after, A/A
  controls within 1 %. The bench shapes give 0.1 ms kernels of which about 20 us is launch.
- **What stands as compiler-level results**: the default policy's `coarsen` wins (1.02x to
  1.11x on 10 kernels, bit-identical `mir` transformations of amdclang's code) and
  `mla_decode`'s 1.49x. Everything else in the session table is what a better source gives
  amdclang.
- Session prompt changed: the machine-level gain is the reported contribution, and the budget
  after the source structure settles goes to the machine IR.

### 2026-11-20 — the per-kernel harness and the first agent sessions (#34, #35 to #60)
- `agc.agent` (`agc agent MANIFEST`, `agc replay`): a headless Claude Code session per kernel
  with the agc MCP tools as its only way to act. The harness reruns the static check and the
  full battery on the state the agent names and times it with 240 pairs until two timings are
  valid (CI narrower than 4 % of the speedup); a win needs both, the lower one is recorded.
  Recipes (module text, launch, rewritten source) in `bench/llm/sessions/`.
- New in the session: the source level (`source(text, launch, defines, flags)`), `relaunch`,
  launch and appended arguments on `edit_ir`, `adopt`, `verify`, `compare`, `probe`
  (diagnostic timing of an unverified state), `battery`, `find`, `liveness`, block views and an
  outline for large kernels, spill warnings, `pairs` on `bench`, memory traffic and headroom.
- Verified session results so far (lower of two 240-pair timings): `moe_gate_topk` 17.97x,
  `attn_decode` 7.40x, `vl_moe_align` 5.90x, `fa_attention` 3.86x, `mla_decode` 2.54x,
  `fa_attention_causal` 2.19x, `rb_gemvn` 2.19x, `fi_rope` 2.12x, `mo_reduce_sum` 1.86x,
  `rb_nrm2` 1.40x, `fi_silu_and_mul` 1.04x. All but the last two are above the 1.5x target.
  None is bit-identical with amdclang unless its issue says so; all meet the manifest tolerance.
- Memory floor: amdclang's copy kernel takes 20 us + bytes / 5.95 TB/s from 2^24 to 2^28 floats,
  and no restructuring of the copy beat it (wider per-lane accesses 0.75x to 1.01x, several
  chunks per wave 0.83x to 0.97x). `bench` reports a kernel's time over this model (headroom).
  About half of the benchmark sits at headroom 0.9 to 1.3: for those 1.5x is not reachable by
  moving the same bytes, and the sessions converge at 1.03x to 1.10x.
- Fixed on the way: `coarsen` gave wrong results when two waves of a workgroup share LDS
  (`kda_step` failed the battery; a barrier now ends each virtual workgroup, #30); the static
  check rejected amdclang's scratch spill code and a `vcc_lo` destination of `v_readlane`;
  harness verification rejected a real win on one disturbed timing.
- Open: sessions for the remaining kernels; no scratch tensor or second launch for reductions
  across workgroups; `unroll_loads` refuses exec-masked loops; the undefined-read warning does
  not follow per-lane masks. The full GPU test suite was not rerun on this branch.

### 2026-11-20 — LLM-kernel benchmark, first policy table (#29)
- `bench/llm`: 36 kernels, each with a manifest, a NumPy reference and provenance
  (`README.md`, `LICENSES.md`): 30 extracted from FlashInfer, vLLM, rocBLAS and MIOpen, and 6
  ports (attention plain and causal, decode attention, MLA decode, KDA step, MoE top-k
  gating). All pass the battery with amdclang's build. Some upstream kernels were skipped
  (sampling, KV append, vLLM top-k softmax); several of those skips were judged without
  reading the kernel bodies. `mla_decode`'s 576/512 split was not checked against FlashMLA.
- `scripts/llmbench.py` records `tests/baselines/llm-gfx950.json`; the table is in
  `docs/report.md`. A reference file may define `<function>_scale` for the `cond` magnitude.
- Default policy, no agent session yet: **10 wins, 26 fallbacks**, geomean 1.015 with
  fallbacks at 1.0. Every win is `coarsen`, 1.015x to 1.113x (`mo_glu_fwd` 1.11x, `rb_rot`
  1.08x, `fi_merge_states` 1.07x). All six ports and every vLLM kernel are fallbacks.
- The benchmark exposed four static-check false positives on amdclang's own code (11
  kernels could not be run at all): `v_readfirstlane_b32` without a suffix; the
  `gpr_idx(...)` operand of `s_set_gpr_idx_on`; the unread half of a two-register source of
  a `v_pk_*` instruction (`op_sel`, `op_sel_hi`); vector memory operations in flight at an
  `s_barrier`. The barrier rule now requires LDS operations and loads into LDS to be
  complete; vector loads stay pending across it. Transforms refuse kernels that use indexed
  vector registers, which the register analyses do not model.
- Open: the 26 fallbacks, one agent session per kernel. The full GPU test suite was not
  rerun after the checker changes.

### 2026-11-20 — `coarsen` pass (#30), positioning (#29)
- `agc/mir/coarsen.py`: one launched workgroup runs `factor` consecutive workgroups of the
  original. The kernel body becomes a loop over virtual workgroup ids; exec, the kernarg
  pointer and the workitem ids are restored per iteration; the loop stops at the original
  `grid_x`, which arrives as one appended `u32` argument (reads of `gridDim.x` are redirected
  to it). Refused: an exit that skips an `s_barrier`, a stack, preloaded arguments, a
  kernarg pointer that escapes.
- Transforms can change the launch: `apply` records grid, block and appended arguments with
  the state, and the worker packs the appended arguments after the manifest's.
- Measured (paired against amdclang, bit-identical, battery passed): `axpy` 1.10x,
  `cast_bf16` 1.25x, `gelu` 1.31x (best factor each). Losses: `matvec` 0.52x at factor 2
  (64 workgroups: the grid is too small to give up parallelism), `transpose` 0.88x, the
  LDS/barrier row kernels 0.91x to 0.97x. `gemm_tiled` is refused (an exit skips a barrier).
- Default policy re-recorded with `coarsen(2|4|8)` candidates: 10 wins and 3 fallbacks as
  before, geomean 1.42 without the MFMA GEMM; `axpy` is now won by `coarsen(8)` (1.105x,
  bit-identical) instead of a generated kernel. The generated kernels still beat `coarsen`
  on `gelu` and `cast_bf16` (1.68x and 1.62x).
- Design and roadmap: agc is a harness for per-kernel agent optimization (D11, principle 6,
  M10); general passes and the policy are the floor a session starts from.
- Open: the LLM-kernel benchmark (#29) is being assembled; no result on it yet.

### 2026-11-19 — Codex review findings (#27)
- All 20 findings on #14 to #25 addressed (2 were already fixed by later PRs); one regression
  test per finding in `tests/test_review_fixes.py`.
- Timing (P1): the launch is prepared before the start event, so the timed interval holds only
  the submission call and the kernel. Protocol is now `agc-timing-amd-2`; every record was
  re-measured (`baseline`, `generated`, `gemm`, `policy`, `wins`, `report` scripts). Absolute
  times of short kernels dropped (AXPY 0.183 to 0.164 ms) and ratios moved away from parity, as
  the review predicted: policy geomean without the MFMA GEMM 1.39 to 1.42; best of policy and
  agent 1.43 to 1.46; MFMA GEMM 2.5x to 2.7x hipBLASLt's time (was 2.8x to 3.2x). The numbers in
  the entries below are under `agc-timing-amd-1`; `docs/report.md` has the current ones.
- Session identity (P1): covers the contents of the HIP source and its includes, file-backed
  reference and tensor programs, and the protocol; a change opens a new session, so no cached
  verdict or timing survives a change of oracle or baseline.
- HIP builds: outputs built in a private directory and published atomically; `-cuid` fixed, so
  two builds of one source are now byte-identical (clang hashed the output path into a symbol).
- Baselines carry toolchain and protocol per kernel.
- Cross-check: alignment padding is computed from offsets, not guessed from `s_nop`s; an entry
  label that differs from the kernel name is printed.
- Waitcnt: `s_memtime` / `s_memrealtime` are pending scalar results; a DS write while a
  direct-to-LDS load is in flight is a finding.
- Session `edit`: at one address the replacement or deletion applies before the insertion.
- Generators: an in-place rowwise tensor advances its address once; `cast_f32(cast_bf16(x))`
  restores the float; a tair reference returns the manifest's output names; GEMM refuses a K
  that depends on a dynamic symbol.
- `unroll_loads`: elements of a loaded tuple are renamed; loops with two loads into one
  register, or arithmetic that reads the counter or a pointer, are refused.

### 2026-11-19 — M9: campaigns and report (#13)
- Agent session on `row_argmax` (the policy's fallback) through MCP: a bulk loop for the
  all-lanes-active iterations, written without waits or nops; `static_check` listed what was
  missing, `apply fix_waits` and `apply fix_hazards` placed it; battery 77/77; 1.34
  (1.32 to 1.35), bit-identical. Body and trace in `tests/mir/wins/`, replayed by a GPU test.
- `transpose` and `gemm_tiled` stay fallbacks: an edit cannot change the launch geometry, and
  neither has a counted load loop; they need templates (a 2-D layout template, an f32 GEMM).
- `.claude/skills/agc-notes`: what paid, what did not, machine facts and the rules that bit,
  from the sessions of M5 to M9.
- `docs/report.md`, generated by `scripts/report.py` from the records: per-kernel policy and
  agent results, GEMM against hipBLASLt, A/A controls, what did not work, how to reproduce.
- Summary: policy alone 10 wins / 3 fallbacks over 13 kernels, geomean 1.39 without the MFMA
  GEMM; with the agent sessions' best per kernel 1.43. MFMA GEMM: 380x amdclang, 2.8x behind
  hipBLASLt (target 1.5x not met; follow-up #23).
- Open (all in the roadmap's stretch table): LDS GEMM (#23), attention (#12), FP8, machine-model
  calibration (#7), trace retrieval and recipe promotion, the interpreter, the profiler.

### 2026-11-19 — M8: backend passes for imported code, default policy (#8)
- `agc/mir/loops.py`: recognition of single-block counted loops (counter, induction pointers
  with constant or loop-invariant strides, loads, vector arithmetic) and `unroll_loads`: N
  iterations' loads in flight per wait (contiguous `dword` streams become `dwordx4` /
  `s_load_dwordxN`, others get offsets, strided streams advance between loads), the arithmetic
  repeated in the original order, the original loop kept for the remainder. Bit-identical by
  construction. A session transform with `factor`, `loop` and `wide` as knobs; `explain` gives
  the reason when a loop does not qualify.
- `agc/session/policy.py` + `agc optimize`: the default policy. Candidates are the import with
  `unroll_loads` at 4 / 8 / 16 and the tensor program with every parameter of its template; each
  goes through static checks, the full battery and a paired timing; the best verified win is
  kept, otherwise the amdclang build, reported as a fallback.
- The policy on every manifest (`scripts/policy.py` → `tests/baselines/policy-gfx950.json`):

| Kernel | Path | Chosen | Speedup vs amdclang (95 % CI) | Bit-identical |
|---|---|---|---|---|
| `axpy` | generate | elementwise(elements_per_lane=4) | 1.048 (1.044 to 1.055) | no |
| `cast_bf16` | generate | elementwise(elements_per_lane=4) | 1.508 (1.493 to 1.516) | no |
| `gelu` | generate | elementwise(elements_per_lane=2) | 1.573 (1.555 to 1.580) | no |
| `gemm_bf16` | generate | gemm_mfma(tiles=2, unroll=2) | 164.099 (161.733 to 165.260) | no |
| `gemm_naive` | import+pass | unroll_loads(factor=16) | 2.200 (2.198 to 2.202) | yes |
| `gemm_tiled` | amdclang | the amdclang build (no verified win) | fallback (1.0) | yes |
| `layernorm` | generate | rowwise(unroll=4) | 1.490 (1.485 to 1.494) | no |
| `matvec` | import+pass | unroll_loads(factor=16) | 2.738 (2.731 to 2.750) | yes |
| `rmsnorm` | generate | rowwise(unroll=4) | 1.446 (1.440 to 1.452) | no |
| `row_argmax` | amdclang | the amdclang build (no verified win) | fallback (1.0) | yes |
| `row_sum` | generate | rowwise(unroll=4) | 1.222 (1.214 to 1.228) | no |
| `softmax` | generate | rowwise(unroll=4) | 1.314 (1.310 to 1.319) | no |
| `temperature_softmax` | generate | rowwise(unroll=4) | 0.3297 ms, no baseline | no |
| `transpose` | amdclang | the amdclang build (no verified win) | fallback (1.0) | yes |

  10 wins and 3 fallbacks over 13 kernels with a baseline. Geomean 1.389 without the MFMA
  GEMM (fallbacks counted as 1.0), 2.006 with it. The policy is never slower than amdclang:
  with no verified win it ships amdclang's build.
- The pass reproduces the M5 hand edits without help: `matvec` 2.74 (hand: 2.70), `gemm_naive`
  2.20 (hand: 2.18). On the HIP bf16 GEMM loop (`ushort` loads, not widened) it measures 0.99 and
  0.97 and is not chosen.
- Fallbacks: `transpose` (no loop, no template), `gemm_tiled` (LDS loop with barriers: not a
  counted load loop; no f32 GEMM template), `row_argmax` (masked loop; no index reduction in
  the rowwise template).
- Open: `bulk_unmasked` for masked loops; widening of 16-bit streams; an f32 GEMM template.

### 2026-11-19 — M7: GEMM on MFMA (#11)
- MFMA layouts measured on the device: a probe kernel written in `mir` (one MFMA on operands
  loaded lane by lane) matches the layout model on the whole battery, for
  `v_mfma_f32_32x32x16_bf16` and `v_mfma_f32_16x16x32_bf16`. The layouts are in
  `gfx950.yaml` (`mfma.layouts`, source `measured`).
- tair `einsum`; corpus kernel `gemm_bf16`: `C[M,N] = A[M,K] @ B[N,K]^T`, bf16 in, f32 out (the
  linear-layer form: both operands contiguous along K), with a HIP version for amdclang.
- `agc/gen/gemm.py` (`gemm_mfma`): each lane loads its 8 bf16 of A and of B with one `dwordx4`
  load, directly in MFMA operand layout; a wave computes `tiles x tiles` output tiles of
  32 x 32 in AccVGPRs (`tiles` + `tiles` loads feed `tiles^2` MFMAs); `unroll` K-steps per wait;
  edges clamped for loads and masked for stores. No LDS, no barrier.
- `agc/runtime/baselines.py` + `native/hipblaslt_bench.cpp`: hipBLASLt timed with the same
  sampling, through the executor (`external` job). Worker job `run` returns raw outputs (probes).
- Results (`scripts/gemm.py` → `tests/baselines/gemm-gfx950.json`); all 6 variants pass the
  battery 77/77:

| Shape | M x N x K | amdclang ms | agc ms | hipBLASLt ms | vs amdclang (95 % CI) | agc / hipBLASLt time | agc TFLOPS | Best variant |
|---|---|---|---|---|---|---|---|---|
| square | 4096 x 4096 x 4096 | 119.72 | 0.3064 | 0.1107 | 391x (389 to 392) | 2.77x | 448 | tiles 4, unroll 2 |
| wide | 2048 x 8192 x 4096 | 119.58 | 0.3140 | 0.1096 | 381x (379 to 386) | 2.86x | 438 | tiles 4, unroll 2 |
| tall | 8192 x 2048 x 4096 | 119.65 | 0.3171 | 0.1068 | 378x (376 to 380) | 2.97x | 434 | tiles 4, unroll 2 |
| small | 2048 x 2048 x 2048 | 14.99 | 0.0928 | 0.0290 | 161x (160 to 162) | 3.20x | 185 | tiles 2, unroll 2 |

- amdclang emits no MFMA for the HIP kernel, hence the two orders of magnitude. The meaningful
  bar is hipBLASLt, and agc is 2.8x to 3.2x behind it.
- Gap analysis (square shape, by variant: tiles 1 unroll 1: 1.054 ms; tiles 1 unroll 2: 0.961 ms; tiles 2 unroll 1: 0.547 ms; tiles 2 unroll 2: 0.538 ms; tiles 4 unroll 1: 0.310 ms; tiles 4 unroll 2: 0.306 ms): the kernel is bound by operand-load throughput.
  The load traffic is 7 to 8 TB/s whatever the variant; halving the bytes loaded per output
  (64x64 → 128x128 outputs per wave) gives 1.7x; twice as many loads per wait gives nothing.
  128x128 per wave is the limit of the 256 AccVGPRs, at 1 wave per SIMD. The next factor of two
  needs operands shared between the waves of a workgroup through LDS (follow-up #23).
- The M7 target (within 1.5x of hipBLASLt on one shape) is not met; the exit criterion
  (verified at three shapes, CI-separated win over amdclang, gap reported and analysed) is.
- Found on the way: the hipBLASLt harness passed the operands in the wrong order, which only
  failed (illegal address) for non-square shapes; fixed before recording.
- Open: only the `A @ B^T` form with K a multiple of 16; no f16 / FP8; no LDS.

### 2026-11-19 — M6: tensor programs in, binaries out (#10)
- `agc/tair`: tensor programs (elementwise maps and reductions over the last axis), text form,
  NumPy interpreter; a manifest's `program` (the input) and/or `reference` (the oracle). The
  interpreter and the corpus's Python references are two independent definitions and agree.
- `agc/gen/builder.py`: kernels built with virtual registers; linear-scan allocation (tuple
  alignment, intervals extended across loops). `agc/mir/passes.py`: `fix_waits` and
  `fix_hazards` insert exactly what the checkers ask for, at the latest point; also session
  transforms.
- `agc/gen/expr.py`: tair expressions to per-lane instructions (FMA fusion, constants pooled in
  SGPRs, `exp` / `tanh` / division through `v_exp_f32` / `v_rcp_f32` under the manifest's
  tolerance). Templates: `elementwise` (several elements per lane, wide loads and stores,
  element computations interleaved) and `rowwise` (one wave per row, reductions combined with
  DPP and `v_readlane`: no LDS, no barrier; 4 elements per lane per 256-column chunk; `unroll`
  chunks per wait).
- Session `program()` / `generate(template, params)`, MCP tools, `agc run --generate`. A
  generated kernel carries its own launch geometry; the runtime applies it per code object.
- Results (`scripts/generated.py` → `tests/baselines/generated-gfx950.json`): 7 tensor programs,
  21 variants, every one on the full battery, paired against amdclang's build of the HIP version:

| Program | Template | Battery | amdclang ms | agc ms | Speedup (95 % CI) | By parameter |
|---|---|---|---|---|---|---|
| `axpy` | elementwise | 49/49 | 0.180 | 0.170 | 1.056 (1.049 to 1.061) | 1: 0.97, 2: 1.03, 4: 1.06 |
| `cast_bf16` | elementwise | 49/49 | 0.159 | 0.106 | 1.498 (1.492 to 1.506) | 1: 0.97, 2: 1.47, 4: 1.50 |
| `gelu` | elementwise | 49/49 | 0.190 | 0.120 | 1.584 (1.572 to 1.589) | 1: 1.09, 2: 1.56, 4: 1.58 |
| `layernorm` | rowwise | 77/77 | 0.472 | 0.320 | 1.474 (1.465 to 1.478) | 1: 1.29, 2: 1.40, 4: 1.47 |
| `rmsnorm` | rowwise | 77/77 | 0.380 | 0.261 | 1.454 (1.450 to 1.463) | 1: 1.26, 2: 1.39, 4: 1.45 |
| `row_sum` | rowwise | 77/77 | 0.188 | 0.153 | 1.228 (1.219 to 1.234) | 1: 1.20, 2: 1.21, 4: 1.23 |
| `softmax` | rowwise | 77/77 | 0.433 | 0.328 | 1.325 (1.322 to 1.329) | 1: 1.22, 2: 1.29, 4: 1.32 |

  Geomean 1.363 over amdclang (best and default parameters coincide).
  `axpy` is memory-bound, as expected; the 1-element-per-lane elementwise variants are 3 %
  slower than amdclang (reported as losses).
- These kernels are not bit-identical to amdclang's: reductions are summed per lane and then
  across lanes, and `exp`, `tanh` and division use the hardware's approximate instructions. They
  meet the manifests' tolerances on every battery case; that is the contract.
- A manifest with no kernel source (`tests/tensor/temperature_softmax.json`) compiles end to
  end: 77/77 battery cases, 0.33 ms at 32768 x 4096 (no baseline to pair with).
- Bug found by the battery's shape variants: a constant was materialized after the entry
  block's branch, so one path read an unset SGPR. It passed on some devices by luck (the
  register held the right value from an earlier kernel). Fixes: constants are placed at the
  entry; generated code that reads a register undefined on any path is refused (`strict`
  static check for generated states; imported code can only warn, since amdclang does this).
- Open: `row_argmax` (index reductions), `transpose`, `matvec` and GEMM have no template yet
  (GEMM is M7); 16-bit and 8-bit inputs; the elementwise tail handles one element at a time.

### 2026-11-19 — M5: the agent loop on assembly (#9)
- `agc/store`: content-addressed immutable states, results attached per state, tags, branches
  (fork / checkpoint / rollback), notes, trace export.
- `agc/session`: `open` (amdclang build imported as `ref`), `state` (numbered listing),
  `features`, `actions`, `edit` (addressed ops with `expect`), `edit_ir` (whole body), `apply`
  (transform registry, empty until M8), `static_check`, `check`, `bench` (paired against `ref`),
  `asm_diff`, `trace`, `best`, tags and branches. Refusals are structured (`kind`, `location`,
  `values`, `suggestion`). A state that fails the static checks gets no GPU job; a state that
  fails the battery is never timed.
- `agc/mcp/server.py` (22 tools, including `isa` and `arch` lookups), `.mcp.json`,
  `scripts/agc_mcp.py` (shell client), the `agc` skill, CLI `agc run`.
- Agent sessions through MCP (Claude driving the tools), paired against amdclang -O3 at the
  bench shapes, full battery:

| Kernel | Edit | Battery | Speedup (95 % CI) | Outcome |
|---|---|---|---|---|
| `matvec` | dot-product loop unrolled x4: `dwordx4` vector + scalar loads, one wait | 77/77 | 2.287 (2.227 to 2.312) | win |
| `matvec` | unrolled x8 | 77/77 | 2.536 (2.526 to 2.544) | win |
| `matvec` | unrolled x16 (`s_load_dwordx16`) | 77/77 | 2.697 (2.690 to 2.709) | win |
| `gemm_naive` | k loop unrolled x4: A row as `dwordx4`, 4 strided B loads per wait | 105/105 | 2.122 (2.119 to 2.129) | win |
| `gemm_naive` | unrolled x8 | 105/105 | 2.181 (2.177 to 2.184) | win |
| `row_sum` | bulk loop for the all-lanes-active iterations, 4 loads per wait via load offsets | 77/77 | 1.278 (1.263 to 1.290) | win |
| `axpy` | all arguments in one `s_load_dwordx8`, one wait fewer | 49/49 | 0.9995 (0.993 to 1.004) | parity |
| `matvec` | first x4 attempt with `v[5:8]` | not run | refused by `static_check` (assembler: tuple must start on an even register) | rejected |

  Every win keeps the floating-point operations in the original order, so results are
  bit-identical to amdclang's. Bodies and traces: `tests/mir/wins/`; a GPU test replays them.
- What the loop showed: amdclang issues one load per loop iteration and waits for it
  (`s_waitcnt vmcnt(0)` in every iteration), so these loops run at memory latency, not
  bandwidth. More loads in flight per wait is the whole win; reordering or removing scalar
  loads on straight-line code is parity. This fixes the M8 pass list (roadmap updated).
- Verifier gap found by the second judge (`llvm-mc`): register tuples must start at an even
  VGPR/AGPR and at a multiple of min(size, 4) for SGPRs. Now in `gfx950.yaml` and the verifier.
- Open: `apply` has no transforms yet; sessions are per manifest and toolchain identity; the
  MCP server holds one session at a time.

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
