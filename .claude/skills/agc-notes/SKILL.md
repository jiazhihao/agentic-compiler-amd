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
- Memory: amdclang's copy kernel takes 20 us + bytes / 5.95 TB/s (2^24 to 2^28 floats). No
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
