# Optimizations: the catalog

Every optimization measured on MI355X (gfx950) with agc, by technique. One entry per optimization:
when it applies (the ISA pattern or kernel property to look for), how to apply it (pass, template,
tool or instructions), what it measured, and where the recipe is. Losses and parities are entries
too: they say what not to repeat. Verified results and their recipes are listed in `RECIPES.md`;
`PATTERNS.md` is the short guide for deciding what kind of kernel is in front of you; the per-kernel
files hold the sessions' detailed entries (`INDEX.md`). `kb(query)` searches all of it.

Levels: **pass** = `apply(id, name, params)`, bit-identical, no knowledge of the kernel needed;
**template** = `generate(template, params)` from a tensor program; **edit** = machine-IR edit in a
session; **launch** = `relaunch`; **source** = a rewritten HIP source built by amdclang (its gain is
credited to amdclang and becomes the baseline). Speedups without a qualifier are harness-verified
over the strongest amdclang build (LLM benchmark) or over `amdclang -O3` (corpus).

## A. Memory access

### A1. Loads in flight before one wait (pass `unroll_loads`)
- **Verdict:** pays, up to 2.8x
- **Applies when:** a loop issues one load (or a few) per iteration and waits with `s_waitcnt vmcnt(0)` in every iteration, so the loop runs at memory latency; counted loops (scalar counter, any step) and exec-mask loops.
- **How:** `apply(id, "unroll_loads", {"factor": 4 | 8 | 16})`: the loads of `factor` iterations are issued before one wait, the arithmetic stays in order (bit-identical). Mask loops get a guarded bulk loop followed by the original loop. By hand in a fast path when the pass refuses (indexed registers, stores in the loop, data-dependent exits).
- **Measured:** `matvec` 2.79 (factor 16), `gemm_naive` 2.19, `row_sum` 1.29, `rmsnorm` 1.25, `layernorm` 1.17; `fi_merge_states` 1.11 by hand (4 S loads and 4 V x4 loads in flight in a fast path). Factor 8 to 16 adds 2 % to 6 % over 4. Nothing on loop-free kernels, which already issue everything under one wait.
- **Recipe:** `tests/mir/wins/matvec_unroll16.s`, `gemm_naive_unroll8.s`, `row_sum_bulk4.s`; `bench/llm/sessions/fi_merge_states/`.

### A2. Wide loads for contiguous data
- **Verdict:** pays as part of other rewrites
- **Applies when:** one lane reads consecutive elements with several `global_load_dword`, or a wave-uniform row is read per lane.
- **How:** `global_load_dwordx2/x4` for a lane's consecutive elements; `s_load_dwordx4/x8/x16` for a row every lane uses. A load's 13-bit offset (-4096..4095) reaches neighbouring elements without new address arithmetic. `global_load_dword vdst, v_off32, s[base:base+1]` (scalar base + 32-bit lane offset) removes per-lane 64-bit address arithmetic.
- **Measured:** part of the generated elementwise kernels (1.6 on `gelu`, `cast_bf16`) and the attention recipes; alone on a memory-bound loop-free kernel it is parity (`rb_axpy`, `rb_dot`: 0.99 to 1.00 with 25 % to 60 % fewer instructions).
- **Recipe:** templates `elementwise`, `rowwise`.

### A3. Wave-uniform rows through scalar loads
- **Verdict:** pays on re-reading kernels
- **Applies when:** every lane of a wave reads the same row (a query, a weight row) and amdclang emits per-lane vector loads for it, or reloads it per batch.
- **How:** `s_load_dwordx16` (or x8) once, then the scalars as VALU operands (`v_fmac_f32_e64 acc, sN, vK`). Or keep the row's parts in a few VGPRs per lane across the loop instead of reloading.
- **Measured:** part of `attn_decode` 1.55 (query parts kept in 4 VGPRs, no `s_load_dwordx16` per batch) and `mla_decode` 1.57. On touch-once kernels a scalar-load read path is parity or loss (`mo_bn_infer` 0.976, `fi_merge_state_in_place` 1.000, `mo_reduce_sum` loss).
- **Recipe:** `bench/llm/sessions/attn_decode/`, `mla_decode/`.

### A4. Lanes laid across a row instead of one row per lane
- **Verdict:** pays, 1.55x
- **Applies when:** each lane owns its own row, so one wide load touches 64 rows far apart (for example 4 KB apart), and the rows are re-read many times.
- **How:** let 32 lanes span one 512-byte row (each x4 load reads two contiguous rows), sum the per-lane partial dots with DPP (4 row folds and `row_bcast:15`), write the scalar result where the rest of the code expects it. 16 loads in flight, the next 16 reissued into freed registers.
- **Measured:** `attn_decode` 1.549 (1.548 to 1.551), 105 us against 164 us.
- **Recipe:** `bench/llm/sessions/attn_decode/best.s`, `docs/kernels/` n/a, issue #35.

### A5. Operands loaded straight into MFMA layout
- **Verdict:** pays (prerequisite of MFMA wins)
- **Applies when:** a matrix product feeds `v_mfma_*`.
- **How:** address each lane's load so the loaded registers are the operand with no shuffle. bf16 32x32x16: lane l element e of A is `A[l % 32][8 (l // 32) + e]`, one x4 load per operand. f32 16x16x4: lane l reads `K[row][16 (l // 16) + 4 x + r]` as one x4 load per x; register r of load x is a valid operand because any assignment of four distinct k to the four lane groups is.
- **Measured:** `gemm_bf16` 204x over amdclang (which emits no MFMA); `fa_attention` 2.09.
- **Recipe:** templates `gemm_mfma`, `attention_mfma`; `arch("mfma")` gives the layouts.

### A6. Software pipelining: the next tile's loads before this tile's work
- **Verdict:** pays as part of other rewrites; parity alone at the memory floor
- **Applies when:** a loop over tiles loads, computes, then stores or accumulates, and the loads of tile t + 1 do not depend on tile t.
- **How:** issue the loads of the next tile before the arithmetic or the LDS work of the current one; wait with a weaker `vmcnt(n)` that leaves the new loads in flight.
- **Measured:** part of `vl_moe_align` 1.55 (8 x4 loads of the next tile before the `ds_add`s) and `rb_scal` 1.12. On touch-once elementwise kernels: `rb_axpy` two tiles per wave 1.009 on repeat, `mo_bn_infer` 0.94, `fi_fused_add_rmsnorm` parity.
- **Recipe:** `bench/llm/sessions/vl_moe_align/`, `rb_scal/`.

### A7. Prefetch through idle workgroups
- **Verdict:** pays when one workgroup does the work
- **Applies when:** the grid has many workgroups that exit early (they sit on otherwise idle CUs) and one workgroup reads cold data alone.
- **How:** each idle workgroup issues one discarded in-bounds `global_load_dwordx4` of the data the working workgroup will read, then exits.
- **Measured:** `vl_moe_align`: probe without the cold loads 42.6 us to 26.6 us; 1.039 alone (the LDS atomics hid the rest); part of the 1.546.
- **Recipe:** `bench/llm/sessions/vl_moe_align/`.

### A8. Strided reads: one workgroup per CU
- **Verdict:** parity over amdclang's best geometry; large losses away from it
- **Applies when:** a column-major matrix walked by rows, or any read of 128 to 256-byte fragments at a large stride.
- **How:** 256 workgroups (one per CU) with about 4 KB of fragments in flight per wave. The plateau is 2.6 to 2.9 TB/s against 4.5 for contiguous reads: read a headroom of 1.2 to 1.3 as "at the floor".
- **Measured:** `rb_gemvn`: 256 workgroups 1.00, 128 0.96, 512 0.82 and 0.79, 32 0.47; 16 loads in flight with scalar operands 0.92.
- **Recipe:** none (fallback); `docs/kernels/rb_gemvn.md`.

### A9. Non-temporal loads (pass `stream_loads`)
- **Verdict:** pays 1.2x to 1.7x when the caches hold other data (the cold-cache protocol); parity when they do not. Not a change of the memory floor
- **Applies when:** a kernel reads each element once (elementwise, copies, single-pass reductions, row merges) and runs right after something else wrote a lot of memory. Not when the kernel reads the same data again (attention, GEMM operands).
- **How:** `apply(id, "stream_loads", {"scope": "all"})`: every `global_load_*` gets `sc0 sc1 nt`. Bit-identical. The default policy tries it alone and on top of the best other win. Do not put `nt` on stores.
- **Measured:** under the timing protocol's default (`flush`: a buffer larger than the caches is written before every launch): `rb_copy` 1.139 (1.132 to 1.145); default policy `fi_merge_states` 1.69 with `coarsen(2)`, `fi_silu_and_mul` 1.44, `fi_gelu_tanh_and_mul` 1.36, `fi_merge_state` 1.33, `fi_rope` 1.31, `fi_merge_state_in_place` 1.20, `kda_step` 1.07. Control on `fi_silu_and_mul` (120 pairs, 12 allocations): flush 1.448 (1.437 to 1.460); caches as the previous launch left them (`warm`) 0.996 (0.986 to 1.006); small shapes 1.001 and 0.997. The baseline itself is 96.8 us after a flush and 60.8 us warm: a normal load has to evict what the flush left in the caches and a non-temporal one does not. So the gain is real for a kernel that follows a large write by another kernel, and absent when the caches are clean. `nt` alone on loads 1.09; `sc0` / `sc1` without `nt` parity; `nt` on stores 0.89 to 0.92.
- **Recipe:** pass; default policy. Report the warm control with the result.

## B. Launch geometry

### B1. Coarsening (pass `coarsen`)
- **Verdict:** pays 1.03 to 1.3 on short kernels
- **Applies when:** a short kernel (one element or one vector per thread) launched on a large grid; workgroup-uniform early exits, scratch and offset kernarg pointers are accepted.
- **How:** `apply(id, "coarsen", {"factor": 2 | 4 | 8})`: one launched workgroup runs `factor` consecutive workgroups of the original; the launch shrinks and one argument is appended. Bit-identical.
- **Measured:** corpus `axpy` 1.10, `cast_bf16` 1.25, `gelu` 1.3; LLM benchmark `rb_scal` 1.06, `mo_glu_fwd` 1.06, `fi_merge_states` 1.05, `fi_rmsnorm` 1.04, `rb_copy` 1.03, `rb_rot` 1.03. Loses where a wave already runs long or the grid is small (`matvec` at 64 workgroups 0.5) and for LDS/barrier row kernels (0.9); refuses workitem-dependent early paths (`rb_gemvt`, `kda_step`).
- **Recipe:** default policy (`RECIPES.md`).

### B2. Throttle: workgroups resident per CU (pass `throttle`)
- **Verdict:** pays 1.02 to 1.03 on two kernels only
- **Applies when:** a memory-bound reduction launched with 8 waves per workgroup. Never on kernels with one or two waves per workgroup.
- **How:** `apply(id, "throttle", {"workgroups_per_cu": 4})`: an LDS reservation the code does not use. Bit-identical. Hand-tuned with `relaunch` and `lds`: the optimum is sharp.
- **Measured:** swept over 36 kernels at 4, 2, 1 per CU: `rb_dot` 1.026, `rb_nrm2` 1.032 at 4; parity on other multi-wave kernels; 1.3x to 10x slower on one-wave workgroups. `rb_nrm2`: 32 KB 1.02, 40 KB 0.97.
- **Recipe:** default policy; `bench/llm/sessions/rb_dot/`, `rb_nrm2/`.

### B3. Bytes per stream per wave: 512 B to 1 KB
- **Verdict:** pays 1.02 to 1.06, mostly through the source
- **Applies when:** an elementwise or reduction kernel whose waves read less than 512 B or more than 1 KB per stream.
- **How:** choose elements per lane and the grid so a wave reads 512 B to 1 KB contiguous per stream; as a `source` state first (amdclang gets the same gain), then machine-level on top.
- **Measured:** 256 B loses 6 % to 16 %, 2 KB and more loses 2 % to 13 % (`fi_gelu_tanh_and_mul` 256 B 0.84, 512 B 1.03, 1 KB 1.01, 2 KB 0.98; `rb_nrm2` 2 or 8 KB per wave 93 to 98 us against 86). The machine-level part on top of the source is under 1 %.
- **Recipe:** `bench/llm/sessions/fi_silu_and_mul/`; baselines in `bench/llm/baselines/`.

### B4. Several elements per lane (template `elementwise`)
- **Verdict:** pays 1.5 to 1.7 when the kernel moves 4 bytes per lane
- **Applies when:** an elementwise kernel with one 4-byte element per thread.
- **How:** `generate("elementwise", {"elements_per_lane": 2 | 4})`; 2 and 4 are equal within noise. One element per lane generated is 3 % slower than amdclang.
- **Measured:** `gelu` 1.68, `cast_bf16` 1.62, `axpy` 1.09. On a kernel that already moves 16 bytes per lane it loses (`fi_silu_and_mul` 0.96; copy study: 32 B per lane 0.94, 64 B 0.79, 256 B 0.75).
- **Recipe:** template `elementwise`.

### B5. One wave per workgroup with two tiles' loads in flight
- **Verdict:** pays 1.12 on one kernel; did not transfer
- **Applies when:** one read stream and one write stream, loop-free, at the copy rate.
- **How:** block 64, grid `cdiv(N, 256)`: each wave owns 1 KB contiguous, read as two 512 B tiles with both tiles' loads issued before the first store; mask-free path for full workgroups.
- **Measured:** `rb_scal` 1.124 (1.119 to 1.128). On a second kernel: `rb_axpy` 0.97, `rb_dot` 0.98, `rb_swap` and `mo_active_fwd` parity or loss.
- **Recipe:** `bench/llm/sessions/rb_scal/`.

### B6. More waves per workgroup to shorten a serial chain
- **Verdict:** pays on long per-row loops
- **Applies when:** one wave walks a long loop per row (keys of an attention row) while most SIMDs idle.
- **How:** split the loop over 4 to 8 waves (wave w takes tiles w, w + W, ...), keep partial accumulators per wave, merge once at the end through LDS with two barriers. Pick the count so workgroups about equal the 256 CUs.
- **Measured:** `fa_attention` block 64 to 256: 113 us to 56 us, block 1024 slower again; `fa_attention_causal` 1.76 to 2.20 with 4 waves, 8 no better.
- **Recipe:** `bench/llm/sessions/fa_attention/`, `fa_attention_causal/`; template `attention_mfma` (`waves`).

### B7. Loop-free threads in place of per-thread strided loops
- **Verdict:** pays 1.03 to 1.06 (source level)
- **Applies when:** one workgroup per row whose threads loop over the row in steps of the block size.
- **How:** launch `rows * cdiv(row_groups, block)` workgroups with one 16-byte vector per thread and no loop.
- **Measured:** `fi_silu_and_mul` 1.03 to 1.06 at 4 TB/s where 3x fewer instructions and four strides' loads in flight were parity. Block 64, 256, 1024 within 2 %.
- **Recipe:** `bench/llm/baselines/` (the strengthened baselines).

## C. Reductions

### C1. One wave per row with DPP reductions (template `rowwise`)
- **Verdict:** pays 1.2 to 1.5 over an LDS tree with barriers
- **Applies when:** a row reduction done through an LDS tree with a barrier per level.
- **How:** `generate("rowwise", {"unroll": 4})`, or by hand: `v_add_f32_dpp` row folds, `v_readlane` or `row_bcast` for the final value.
- **Measured:** corpus `layernorm` 1.51, `rmsnorm` 1.45, `softmax` 1.35, `row_sum` 1.30; `rb_gemvt` 1.024 (per-wave DPP + `v_readlane`). Parity or loss where amdclang's reduction is already one level: `rb_dot` 0.99, `vl_fused_add_rms_norm` 0.98.
- **Recipe:** template `rowwise`; `bench/llm/sessions/rb_gemvt/`.

### C2. Fewer, flatter LDS reductions
- **Verdict:** pays on kernels far from the memory floor
- **Applies when:** a tree reduction over many threads (log2 N + 2 barriers), or a maximum taken per small tile.
- **How:** a two-level LDS reduction (2 barriers); one maximum per 2048 keys instead of per 64-key tile; a one-wave workgroup needs no barriers around LDS at all; linear accumulators stay partial per thread and are summed once at the end.
- **Measured:** part of the attention source rewrites (2.5x to 7.4x over `-O3` on the shipped source, credited to amdclang).
- **Recipe:** `bench/llm/baselines/attn_decode.hip`, `fa_attention.hip`.

### C3. Keep the input across the reduction instead of reading it twice
- **Verdict:** pays 1.7 (source level)
- **Applies when:** a reduction pass followed by an update pass over the same input (row norms).
- **How:** keep the row in registers or LDS across the reduction.
- **Measured:** `mo_t5_layernorm` 1.74, `kda_step` 1.70 over the shipped source; once done, the kernel is touch-once and at the floor.
- **Recipe:** `bench/llm/baselines/mo_t5_layernorm.hip`, `kda_step.hip`.

## D. Compute

### D1. MFMA GEMM (template `gemm_mfma`)
- **Verdict:** pays, 200x to 400x over amdclang
- **Applies when:** `C = A @ B^T`, bf16 inputs, f32 result. amdclang never emits MFMA.
- **How:** `generate("gemm_mfma", {"tiles": 1 | 2 | 4, "unroll": 1 | 2})`: `v_mfma_f32_32x32x16_bf16`, `tiles^2` output tiles per wave so a loaded element is used `tiles` times.
- **Measured:** 479 TFLOP/s at 4096^3 (tiles 4); bigger tiles 1.7x from 64x64 to 128x128 outputs per wave; more loads per wait: nothing (bound by operand-load throughput, 7 to 8 TB/s). hipBLASLt is still 2.6x to 2.8x faster: needs LDS-shared operands (issue #23).
- **Recipe:** template `gemm_mfma`; `tests/baselines/gemm-gfx950.json`.

### D2. MFMA attention (template `attention_mfma`)
- **Verdict:** pays, 2.0x to 2.1x
- **Applies when:** `softmax(scale Q K^T) V` per head, f32, row width 64 or 128, where each query (or each few queries) re-reads K and V. As a tensor program: two `einsum`s around a max / exp / sum / divide (see `bench/llm/fa_attention.tair`).
- **How:** `generate("attention_mfma", {"waves": 1 | 2 | 4 | 8, "ahead": 0 | 1})`. `v_mfma_f32_16x16x4_f32`: 16 queries x 16 keys per tile, 16 MFMAs for the scores (A = K, B = Q premultiplied by scale * log2 e) and 16 for the value update (A = the exponentiated scores in place, B = V), so K and V are read once per 16 queries. All operand loads are `dwordx4` straight into operand layout (K: lane l reads columns `16 (l // 16) + 4 x ..`; V: columns `4 (l % 16) ..`). Online softmax with a lazily updated reference (rescale only when a score exceeds it by 2^64; the exact maximum crosses lane groups with `ds_bpermute_b32` on that slow path only). `waves`: the waves of a workgroup take the key tiles in turn and merge once through LDS. `ahead`: the next tile's loads are issued before the current tile's MFMAs. Layout: lane l of A is `A[l % 16][l // 16]`, of B `B[l // 16][l % 16]`, result register r is `D[4 (l // 16) + r][l % 16]`.
- **Measured:** hand-written session recipes: `fa_attention` 2.105 (2.101 to 2.108), 26 us against 55 us; `fa_attention_causal` 1.981 (1.977 to 1.985). The template on `fa_attention` (60 pairs over 6 allocations, battery 77/77): waves 4, ahead 1: 1.959 (1.954 to 1.964), 29.0 us; waves 8: 1.65 with or without ahead; waves 4, ahead 0: 1.47; waves 2, ahead 1: 1.22; waves 1: 0.44. V as 16 single-dword loads per tile instead of 4 wide ones: 1.79. Row width 128 passes the battery.
- **Recipe:** template `attention_mfma` (`agc/gen/attention.py`); `bench/llm/sessions/fa_attention/best.s`, `fa_attention_causal/best.s`.

### D3. More outputs per read of a shared input
- **Verdict:** pays 1.5x to 2x at the machine level, more at the source level
- **Applies when:** attention-like kernels that read K and V once per head or per query.
- **How:** two heads per workgroup (`mla_decode`), four or 16 queries per workgroup (`fa_attention`); when workgroups cannot communicate, split the output and recompute the shared part (`attn_decode`: 8 workgroups per head, each owning 16 output columns).
- **Measured:** `mla_decode` 1.565 (1.564 to 1.566) on top of a source with 4 heads per workgroup; source level over the shipped source: 2.5x to 7.4x.
- **Recipe:** `bench/llm/sessions/mla_decode/`.

### D4. Cheaper math within tolerance
- **Verdict:** parity on memory-bound kernels
- **Applies when:** `exp`, `rcp`, `rsq`, `tanh` chains with range handling the tolerance does not need.
- **How:** bare `v_exp_f32` (2^x), `v_rcp_f32`, `v_rsq_f32`; at the source level `__builtin_amdgcn_exp2f`, `__builtin_amdgcn_rcpf`. Differs from libm at infinities.
- **Measured:** 20 instructions fewer per exp; parity alone on `fi_silu_and_mul`, `fi_gelu_tanh_and_mul` (1.006 to 1.010 at 240 pairs).
- **Recipe:** none.

### D5. Fewer instructions in the body
- **Verdict:** parity at the memory floor; a few percent in load-bound loops
- **Applies when:** always tempting; pays only when arithmetic is on the critical path.
- **How:** fused forms (`v_fmac`, `v_lshl_add_u64`, `v_mad_u64_u32`), scalar work hoisted, compare-and-branch on a decremented counter, `v_min_u32` clamps in place of bounds masks.
- **Measured:** 77 instead of 183 instructions per iteration in a load-bound loop: 1.03. Touch-once kernels: 0.99 to 1.00 with 25 % to 60 % fewer instructions (`rb_axpy`, `rb_dot`, `fi_gelu_tanh_and_mul`, `mo_t5_layernorm`, `mo_bn_infer`). `v_pk_fma` with 4 accumulators 8 % slower than `v_pk_mul` + adds.
- **Recipe:** none.

### D6. Branchless per-lane top-k
- **Verdict:** pays (source level, 18x over the shipped source)
- **Applies when:** top-k per row implemented as k passes over the row.
- **How:** one pass with a sorted top-k kept by a sorting network; compare (order-preserving integer key of the float, ~index) as one signed 64-bit value so ties resolve to the lower index; keep the 32-bit halves in separate variables.
- **Measured:** `moe_gate_topk` 18x at the source level; machine-level on top 1.015.
- **Recipe:** `bench/llm/baselines/moe_gate_topk.hip`, `bench/llm/sessions/moe_gate_topk/`.

## E. LDS

### E1. Per-lane slots for LDS histogram atomics
- **Verdict:** pays, part of 1.55x
- **Applies when:** `ds_add_u32` (or any LDS atomic) from 64 lanes to addresses that often coincide (a histogram with few bins).
- **How:** give each bin 16 slots, address = base + 64 * bin + 4 * (lane & 15); zero them before the barrier; merge the 16 slots with `ds_read2` after it.
- **Measured:** `vl_moe_align`: 8192 adds cost 20 us on shared addresses, 4.5 us lane-distinct; slots 64 / 32 / 16 / 8: 1.24 / 1.41 / 1.54 / 1.37. Verified 1.546 (1.539 to 1.555), bit-identical.
- **Recipe:** `bench/llm/sessions/vl_moe_align/best.s`.

### E2. Masked LDS atomics through a dummy slot
- **Verdict:** pays as part of E1
- **Applies when:** out-of-range indices are masked per element with EXEC.
- **How:** clamp with `v_min_u32` to a dummy slot instead.
- **Measured:** part of `vl_moe_align`.
- **Recipe:** `bench/llm/sessions/vl_moe_align/`.

### E3. Registers in place of scratch
- **Verdict:** essential at the source level
- **Applies when:** `features(id)` reports scratch spills in a loop (amdclang spills beyond 128 VGPRs).
- **How:** keep batches at or below about 16 x4 loads plus temporaries; running outputs in LDS rather than in arrays indexed by a variable.
- **Measured:** the same design 0.63 with 14 spills and 1.76 with none; 91 spills 0.13.
- **Recipe:** none.

### E4. LDS size and occupancy
- **Verdict:** a constraint
- **Applies when:** a kernel allocates much LDS per workgroup.
- **How:** above 80 KB per workgroup only one workgroup fits a CU (163,840 bytes per CU).
- **Measured:** `kda_step` 1.21 against 1.60 with the smaller allocation.
- **Recipe:** none.

## F. Order and control

### F1. Loads before a scalar prologue, stores as soon as their value exists
- **Verdict:** pays 1.025 with many streams
- **Applies when:** a wave runs a scalar prologue (a `pow` loop) or a transcendental chain between its loads and stores, with 5 or more streams.
- **How:** all kernargs at entry under one lgkm wait; the vector loads issued before the prologue; store addresses computed before the first vmcnt wait; stores issued before the remaining transcendental chain.
- **Measured:** `mo_adam` 1.025 (1.024 to 1.027), 7 streams. Parity with 3 streams or fewer: `mo_bn_infer` 1.0005, `kda_step` 0.995, `vl_fused_add_rms_norm` 0.996.
- **Recipe:** `bench/llm/sessions/mo_adam/`.

### F2. Waits later and weaker (pass `fix_waits`)
- **Verdict:** pays when a wait stalls independent work
- **Applies when:** `s_waitcnt vmcnt(0)` directly after the loads, or a full wait where only the oldest load is needed.
- **How:** write edits without waits, then `apply(id, "fix_waits")` (`rewrite=True` re-places every wait at first use with the weakest count).
- **Measured:** part of every loads-in-flight win; alone on straight-line memory-bound code 0.9995 (`axpy`).
- **Recipe:** pass.

### F3. Branch over memory instructions most waves execute with an empty EXEC
- **Verdict:** pays 1.4 %
- **Applies when:** a store or load under a mask that is empty for most waves (one wave of a workgroup writes a per-row result).
- **How:** `s_cbranch_execz` or a scalar test around it.
- **Measured:** `mo_t5_layernorm`: unbranched 0.980, branched 0.994, otherwise identical code.
- **Recipe:** none.

### F4. Mask-free fast path for full workgroups
- **Verdict:** parity at the memory floor
- **Applies when:** every lane carries bounds masks and `s_and_saveexec` regions for a tail that only the last workgroup has.
- **How:** a scalar compare of the workgroup's last element against N, then a straight-line path; the original code as fallback.
- **Measured:** `rb_dot` 0.99, `mo_t5_layernorm` 0.994, `fi_gelu_tanh_and_mul` 1.006 to 1.010.
- **Recipe:** none.

## G. Source level (credited to amdclang; becomes the baseline)

### G1. `-ffast-math`
- **Verdict:** pays on reductions and transcendental kernels
- **Applies when:** the manifest's tolerance covers reassociation.
- **How:** `source(text, flags=["-ffast-math"])`; `scripts/strong_baseline.py run` tries it for every kernel.
- **Measured:** see `tests/baselines/llm-strong-gfx950.json` per kernel. States on such a baseline are within tolerance of the original binary, not bit-identical.
- **Recipe:** manifests' `baseline`.

### G2. Change the algorithm when the source makes repeated passes
- **Verdict:** pays, 6x to 18x over the shipped source
- **Applies when:** k passes over a row (top-k), a looping workgroup that fills an array.
- **How:** one pass with online state; a loop-free 16-byte store per thread.
- **Measured:** `moe_gate_topk` 18x, `vl_moe_align` 5.9x.
- **Recipe:** `bench/llm/baselines/`.

### G3. What amdclang does with a source
- **Verdict:** facts
- **Applies when:** writing a `source` state.
- **How:** it merges load batches, vectorizes short loops into `v_pk_fma` pairs with duplicated operand registers (`#pragma clang loop unroll(disable) vectorize(disable) interleave(disable)` or `-fno-slp-vectorize`), does not remove `x / d * d + x % d`; block (32, 16) puts two 32-row groups in one wave.
- **Measured:** block (32, 16) 1.06 on `rb_gemvn`.
- **Recipe:** none.

## I. Across kernels

### I1. Fusion: two kernels in a row as one generated kernel
- **Verdict:** pays, 1.6x to 2.2x over the two fastest separate kernels, with flushed and with warm caches
- **Applies when:** a kernel that touches every element once consumes the output of another one (a norm followed by an activation, an activation followed by a cast). The intermediate tensor is written by the first and read by the second: at the memory floor that is the whole cost of the second kernel's read and the first one's write.
- **How:** `agc.tair.fuse.fuse(a, b, {input of b: output of a})` composes the two tensor programs; `fuse_manifests` makes the fused manifest (the fused program is also its float64 reference; the first stage's `cond` allowance is kept, scaled by the first stage's magnitude). The existing templates compile it: `rowwise` when the first stage reduces over rows, `elementwise` otherwise. `scripts/fusion.py` measures.
- **Measured:** full battery passed for every fused variant. Fused against the sum of the fastest verified build of each stage (medians over 3 allocations, not paired): `rmsnorm` then `gelu` 1.78 (warm caches 1.74); `layernorm` then `gelu` 1.63 (1.58); `gelu` then `cast_bf16` 2.14 (2.25).
- **Recipe:** `tests/baselines/fusion-gfx950.json`; `scripts/fusion.py`.

## H. Measuring (get these wrong and every number above is wrong)

### H1. Placements: time depends on where the tensors were allocated
- **Verdict:** essential
- **Applies when:** any memory-bound kernel and an effect below about 5 %.
- **How:** `bench` and `compare` spread the pairs over several allocations of the tensors (10 pairs each) and take the CI over the allocations; `placement_speedups` shows the lowest and highest. Use `pairs=240` (24 allocations) for a verdict.
- **Measured:** `rb_axpy`: the baseline is 153 to 164 us depending on the allocation (same virtual addresses, different times); one candidate measured 0.97 to 1.05 across allocations with within-allocation CIs of +/- 0.5 %; over 24 allocations it is 1.006 (1.003 to 1.009), parity. Earlier single-allocation wins near 1.02 to 1.03 on touch-once kernels were artifacts of this.
- **Recipe:** `agc/runtime/timing.py` (issue #66).

### H2. Two equal bounds hide each other
- **Verdict:** essential
- **Applies when:** probes with one phase removed add up to less than the total.
- **How:** probe pairs of phases.
- **Measured:** `vl_moe_align`: 45.5 us; 43.3 without cold loads; 42.6 without atomics; 23.2 without both.
- **Recipe:** `probe(id)`.

### H3. Check which path the battery takes
- **Verdict:** essential
- **Applies when:** a fast path guarded by a shape condition.
- **How:** `battery()` shows the shapes; make sure some reach the fast path, or its correctness is untested.
- **Measured:** `kda_step`: all 13 battery shape variants run the slow loop.
- **Recipe:** none.

### H4. Differential check against the original binary
- **Verdict:** part of the verification
- **Applies when:** every state that is reported.
- **How:** `equivalent(id)`: the original binary and the state's on the same inputs, outputs compared with each other.
- **Measured:** all shipped states within tolerance; bit-identical where the baseline is not a `-ffast-math` build.
- **Recipe:** `scripts/equivalence.py`.

### H0. The cold-cache protocol charges the kernel for evicting the flush
- **Verdict:** essential
- **Applies when:** reading any time or "memory floor" measured with the default `flush` cache policy.
- **How:** compare with `TimingProtocol(cache="warm")`. Part of every time under `flush` is the eviction of the buffer the harness wrote before the launch.
- **Measured:** `fi_silu_and_mul` baseline 96.8 us flush, 60.8 us warm at the same shapes. The floor model (H5) was fitted under `flush`.
- **Recipe:** `agc/runtime/timing.py`.

### H5. The memory floor model
- **Verdict:** a model, not a proof
- **Applies when:** deciding whether 1.5x is possible.
- **How:** `time = 20 us + read / 4.5 TB/s + written / 10.7 TB/s`; a plain copy is 20 us + bytes / 5.95 TB/s. `bench` reports `headroom` against it. It assumes every element is touched once: a kernel that re-reads is not at the floor whatever headroom says.
- **Measured:** fits dot, nrm2, reduce_sum, copy, scal, rot, axpy, layernorm within about 10 %. Kernels at headroom 1.0 to 1.2 gained 1.12 at best.
- **Recipe:** none.
