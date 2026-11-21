---
name: agc-notes
description: What has been learned about optimizing kernels for AMD MI355X (gfx950) with agc - measured facts about the machine, what paid and what did not, and traps. Read before starting an optimization session or writing a generator.
---

# Knowledge notes (from the sessions recorded in docs/progress.md)

Each note says what was measured and where. Numbers are paired speedups over `amdclang -O3` under
the agc timing protocol unless stated.

## What pays

- **Loads in flight per wait.** amdclang emits one load per loop iteration and a full
  `s_waitcnt` in every iteration, so its loops run at memory latency. Issuing N iterations' loads
  before one wait and keeping the arithmetic in order is bit-identical and gave 2.7x (`matvec`,
  N = 16), 2.2x (`gemm_naive`), 1.3x (`row_sum`, `row_argmax`). `apply(id, "unroll_loads")` does
  it for counted loops; masked loops need a hand-written bulk prefix loop
  (`tests/mir/wins/row_sum_bulk4.s`).
- **Coarsening** (`apply(id, "coarsen", {"factor": 2 | 4 | 8})`): one launched workgroup runs
  several consecutive workgroups of the original, bit-identical, no knowledge of the kernel
  needed. It pays for short one-element-per-thread kernels launched on a large grid: 1.10x
  `axpy`, 1.25x `cast_bf16`, 1.3x `gelu`. It loses where a wave already runs long or the grid is
  small (`matvec` at 64 workgroups: 0.5x at factor 2), and for LDS/barrier row kernels (0.9x).
- **Wide loads for contiguous streams** (`global_load_dwordx4`, `s_load_dwordxN`); for strided
  streams the load's 13-bit offset (-4096..4095) reaches the next 3 elements of a 1024-byte stride.
- **Several elements per lane** for elementwise work: 1.5x to 1.6x on `gelu` and `cast_bf16`;
  2 or 4 per lane are equal within noise.
- **One wave per row with DPP reductions** instead of an LDS tree with barriers: 1.2x to 1.5x on
  `row_sum`, `softmax`, `rmsnorm`, `layernorm`.
- **MFMA.** amdclang never emits it. `v_mfma_f32_32x32x16_bf16` with operands loaded straight
  into operand layout is 380x amdclang's bf16 GEMM at 4096-class shapes.

- **Loop-free threads for per-thread strided loops** (`fi_silu_and_mul`, source level). Library
  kernels launch one workgroup per row and let each thread loop over the row in steps of the
  block size. Launching `rows * cdiv(row_groups, block)` workgroups with one group of elements
  (one 16-byte vector) per thread and no loop gave 1.03x to 1.06x at 4 TB/s, where cheaper
  arithmetic (3x fewer instructions) and four strides' loads in flight each measured parity.
  Block 64, 256 and 1024 are within 2 % of each other; block 64 was best under 240-pair timing.
- **Cheaper math within tolerance**: `__builtin_amdgcn_exp2f` lowers to a bare `v_exp_f32`,
  `__builtin_amdgcn_rcpf` to `v_rcp_f32`; `__builtin_exp2f` adds 20 instructions of range
  handling. On a memory-bound kernel this alone is parity; it differs from libm at infinities.

## What pays when the kernel is far from the memory floor (agent sessions, source level first)

Measured on the LLM benchmark; recipes in `bench/llm/sessions/`.

- **Change the algorithm when the source makes repeated passes.** `moe_gate_topk` read each
  row 10 times, one dword per wait: a single pass with an online softmax sum and a sorted top-8
  kept by sorting networks gave 18x. `vl_moe_align`: a looping workgroup that fills an array
  became a loop-free 16-byte store per thread, plus 8 wide loads in flight in the counting
  workgroup: 5.9x.
- **Share loads between outputs that re-read the same data.** Attention kernels read K and V
  once per head or per query. Two heads per workgroup (`mla_decode`) 2.5x; four queries per
  workgroup (`fa_attention`) 3.9x, with an optimum (2 queries 2.5x, 8 queries 3.0x). Pick the
  count so that the workgroups about equal the 256 CUs.
- **Split the output, recompute the shared part** when workgroups cannot communicate:
  `attn_decode` with 8 workgroups per head, each recomputing the scores and owning 16 output
  columns: 7.4x (2 / 4 / 8 workgroups: 6.5x / 7.3x / 7.4x).
- **Loads in flight**: 16 `global_load_dwordx4` per wait for key rows, 16 to 32 for values.
  Prefetch loads into dead registers cost 10 %.
- **Fewer, flatter reductions**: a two-level LDS reduction over 1024 threads (2 barriers) instead
  of a tree (log2 N + 2 barriers); one max per 2048 keys instead of per 64-key tile; a
  one-wave workgroup needs no barriers around LDS at all.
- **More waves per workgroup shorten serial chains** (`fa_attention` block 64 -> 256: 113 us ->
  56 us; block 1024 slower again). Splitting a long per-row loop over 4 waves with one final
  LDS merge: 1.76x -> 2.20x (`fa_attention_causal`); 8 waves no better.
- **A wave-uniform, loop-invariant row belongs in SGPRs**: amdclang loads the query with
  `s_load_dwordx16` and uses the scalars as VALU operands, sometimes; when it emits per-lane
  loads instead, do it by hand (`v_fmac_f32_e64 acc, sN, vK`).
- **Linear accumulators stay partial per thread** and are summed once at the end through LDS.
- **Branchless per-lane top-k**: compare (order-preserving integer key of the float, ~index)
  as one signed 64-bit value: ties resolve to the lower index and any sorting network is right.
  Keep the 32-bit halves in separate variables, or clang emits two 64-bit compares per exchange.
- **Masked LDS atomics**: clamp out-of-range indices with `v_min_u32` to a dummy slot instead
  of masking EXEC per element.

## What does not pay

- **Memory-bound elementwise kernels**: `axpy` is at about 4.7 TB/s; fewer scalar loads or waits
  on straight-line code measured 0.9995 (parity). Expect at most a few percent.
- **More unrolling once loads are batched**: x8 to x16 adds 2 % to 6 %.
- **More loads per wait in the MFMA GEMM**: nothing. That kernel is bound by operand-load
  throughput (7 to 8 TB/s); only fewer bytes per output help (bigger tiles: 1.7x from 64x64 to
  128x128 outputs per wave). hipBLASLt is still 2.8x faster; closing that needs LDS-shared
  operands (issue #23).
- **One element per lane in a generated elementwise kernel**: 3 % slower than amdclang.
- **Several 16-byte vectors per thread on a kernel that already moves 16 bytes per lane**
  (`fi_silu_and_mul`): 0.96x, and `coarsen` on the loop-free state 0.99x. The 1.5x of "several
  elements per lane" is for kernels that move 4 bytes per lane.

## Machine facts (measured here)

- Kernels under about 50 us are dominated by launch overhead (18 to 28 us): use `bench_shapes`.
- A/A controls stay within 1 %; `win` / `loss` need the whole 95 % CI beyond 1 %.
- Effects of a few percent: 60 pairs give a CI of about +/-1.2 %, 240 pairs about +/-0.6 %
  (`bench(id, pairs=240)`), and two runs of the same state can differ by 1 % to 2 % because the
  clock level differs between runs. Rank close candidates with `compare(a, b, pairs=240)`. The
  harness accepts a win only when two 240-pair timings are both wins.
- Memory floor: one cold pass streams at about 4.5 TB/s read and 10.7 TB/s written, after 20 us
  of launch: `time = 20 us + read / 4.5 + written / 10.7` fits dot, nrm2, reduce_sum, copy, scal,
  rot, axpy and layernorm within about 10 %. The 7.5 TB/s of the MFMA GEMM is for operands
  that are re-read from cache. `bench` reports `headroom` against this floor; sessions that
  reached headroom 1.0 to 1.1 found nothing more (`mo_t5_layernorm`, `kda_step`, `rb_nrm2`).
- Reading less is the lever at the floor: kernels that read an input twice (a reduction pass,
  then an update pass) keep it in registers or LDS across the reduction instead
  (`mo_t5_layernorm` 1.74x, `kda_step` 1.70x); values shared between outputs are computed once
  (`fi_rope`: sin/cos once per position for 4 heads, 2.1x).
- A wave should read about 1 KB contiguous: 2 KB or 8 KB per wave read slower (93 to 98 us
  against 86 us, `rb_nrm2`). An LDS allocation above 80 KB per workgroup halves the workgroups
  per CU (`kda_step`: 1.21x against 1.60x).
- Copy study: amdclang's copy kernel is 20 us + bytes / 5.95 TB/s (2^24 to 2^28 floats). No
  restructuring beat it: 16 bytes per lane 1.01 (parity), 32 bytes per lane 0.94, 64 bytes per
  lane 0.79, 256 bytes per lane 0.75, and several lane-contiguous chunks per wave with all loads
  before the stores 0.97 (2 chunks) down to 0.83 (16 chunks). Many short waves that each touch a
  contiguous 0.5 to 1 KB are what the memory system likes. `bench` reports `headroom`: a
  kernel's time over this copy model. Kernels at headroom 1.0 to 1.2 gained 1.03x to 1.10x at
  best (loop-free threads, `coarsen`); 1.5x needs headroom, or fewer bytes.
- Clocks float between 500 / 1012 / 2400 MHz levels on the SR-IOV VFs and cannot be locked.
- MFMA layouts (`arch("mfma")`, `layouts`): for 32x32x16 bf16, lane l element e of A is
  `A[l % 32][8 (l // 32) + e]`, of B is `B[8 (l // 32) + e][l % 32]`; result register r is
  `D[8 (r // 4) + 4 (l // 32) + r % 4][l % 32]`.
- All corpus kernels are at the hardware occupancy limit (8 waves per SIMD); registers only
  matter for MFMA kernels (256 AccVGPRs leave 1 wave per SIMD).

## amdclang at the source level

- It keeps a kernel within 128 VGPRs and spills beyond that to scratch. **Scratch in a loop
  is fatal**: the same design ran at 0.63x with 14 spills and 1.76x with none; 91 spills
  0.13x. `features(id)` warns; keep batches at or below about 16 x4 loads (64 registers) plus
  temporaries, and keep running outputs in LDS rather than in arrays indexed by a variable.
- It merges source-level load batches (24 + 8 became 32), vectorizes short loops over queries
  into `v_pk_fma` pairs with duplicated operand registers (`#pragma clang loop unroll(disable)
  vectorize(disable) interleave(disable)`, or `flags: ["-fno-slp-vectorize"]`), and does not
  remove `x / d * d + x % d`.
- Cutting ALU instructions in a load-bound loop pays little (77 instead of 183 per iteration:
  1.03x); `v_pk_fma` with 4 accumulators was 8 % slower than `v_pk_mul` + adds with scalar
  operands.
- `headroom` assumes each tensor element is touched once. Attention-like kernels re-read their
  inputs hundreds of times: work out the real traffic before choosing a lever.

- Strided reads (a column-major matrix walked by rows: 128 to 256-byte fragments at a 32 KB
  stride, `rb_gemvn`) plateau at 2.6 to 2.9 TB/s against 4.5 TB/s for contiguous streams: read a
  `headroom` of 1.2 to 1.3 on such a kernel as "at the floor". There the time is set by the
  launch geometry, not the loop body: one workgroup per CU (256) with 8 waves each was best;
  16 dword loads in flight with a pipelined `vmcnt(8)` wait and scalar operands was 0.92x
  against amdclang's 10 loads and a full wait per iteration.
- A lane group narrower than a wave is a source-level knob: block (32, 16) puts two 32-row
  groups in one wave and doubles the workgroups at the same wave count (1.06x on `rb_gemvn`).
- `global_load_dword vdst, v_off32, s[base:base+1]` (scalar base + 32-bit vector offset) is
  legal and removes per-lane 64-bit address arithmetic.

- **MFMA for attention** (`fa_attention`, 2.09x over the strongest amdclang build):
  `v_mfma_f32_16x16x4_f32` computes 16 queries x 16 keys per tile, 16 MFMAs for the scores and
  16 for the value update, so K and V are read once per 16 queries. Layout, verified by the
  battery: lane l element of A is `A[l % 16][l // 16]`, of B is `B[l // 16][l % 16]`; result
  register r lane l is `D[4 (l // 16) + r][l % 16]`.
- A kernel that re-reads its inputs once per workgroup is not at the memory floor whatever
  `headroom` says: the levers are fewer re-reads (more queries or heads per workgroup, MFMA
  tiles), wave-uniform rows read with `s_load_dwordx16` and used as scalar operands, and 16 wide
  loads in flight per wait (`mla_decode` 1.56x, `attn_decode` 1.55x, `fa_attention_causal` 1.99x).
- Elementwise and reduction kernels that touch each element once measured parity for every
  machine-level rewrite tried in round 2 (DPP in place of LDS trees, scalar loads, fewer VALU,
  merged waits, coarsening): their time is the loads themselves.

## Rules that bit

- Register tuples start on an even VGPR/AGPR and on a multiple of min(size, 4) for SGPRs
  (`v[5:8]` is rejected by the assembler; the verifier knows this now).
- amdclang prints no label after a conditional branch: every block must be a basic block or a
  path is missed (the parser splits blocks at branches).
- A value must be defined on every path that reads it. A constant materialized after a branch
  passed the battery on some devices because the register happened to hold the right value;
  generated code is checked strictly (`static_check` refuses it).
- The installed amdclang places no wait states when two different MFMAs share an accumulator;
  newer LLVM requires them (6 after a 4-pass MFMA). agc keeps the stricter rule.
- hipBLASLt is column-major: `C = A @ B^T` in row-major is `C' = B'^T @ A'`; with the operands
  swapped it only fails for non-square shapes.

## How to work

- Write edits without waits and nops, then `apply(id, "fix_waits")` and
  `apply(id, "fix_hazards")`; `static_check` says exactly what is missing otherwise.
- Keep floating-point operations in order when editing imported code: the result stays
  bit-identical and the battery cannot disagree about rounding.
- Report parity and losses. `transpose` and `gemm_tiled` have no win under a fixed launch
  geometry; they need a generator, not an edit.
