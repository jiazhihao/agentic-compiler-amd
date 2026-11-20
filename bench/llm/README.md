# bench/llm: kernels of the LLM stack

GPU kernels that an LLM inference / training stack runs, as standalone HIP sources with a manifest
(`<name>.json`) and a NumPy reference (`refs.py`), each verified on the GPU by `agc check`.

Two kinds, kept apart:

- **extracted**: the device code of a library, instantiated for float32 and for the launch the library's
  own launcher would do. The algorithmic structure is the library's: thread-to-element mapping, block
  sizes, loops, LDS reductions, shuffles, early-outs. What was instantiated or removed is listed per kernel.
- **port**: written for this benchmark from a reference that is not extractable device code (a paper, a
  Python reference, or a kernel too entangled with NVIDIA-only machinery). Ports are not library code and
  must not be presented as such; see [Ports](#ports).

## Sources

| Project | Commit | License | Used for |
|---|---|---|---|
| [ROCm/rocm-libraries](https://github.com/ROCm/rocm-libraries) | `207bc1a58e952051e9103687e1b60db0d72361be` | MIT | rocBLAS (`rb_*`), MIOpen (`mo_*`) |
| [flashinfer-ai/flashinfer](https://github.com/flashinfer-ai/flashinfer) | `5cd7ab08e2a7e4b607f011080f3601350ce95fdc` | Apache-2.0 | `fi_*` |
| [vllm-project/vllm](https://github.com/vllm-project/vllm) | `efb6ed2fe36ae358ed3b001e51221ef411484113` | Apache-2.0 | `vl_*` |
| [deepseek-ai/FlashMLA](https://github.com/deepseek-ai/FlashMLA) | `395cb3afbb331fef7b1b21e9340861b9436b42d8` | MIT | reference of the port `mla_decode` |
| [fla-org/flash-linear-attention](https://github.com/fla-org/flash-linear-attention) | `42c22207f6767e7cf5e46e89be70fd0d9040776d` | MIT | reference of the port `kda_step` |

License texts: [LICENSES.md](LICENSES.md). The extracted files are modified copies (Apache-2.0 section 4b):
every `.hip` and helper header names its upstream file and function in its first lines, and the tables below
state the changes.

## Conventions

- Entry points are `extern "C" __global__ void <name>(...)` with plain pointers and scalars; the manifest
  name, the entry and the file name are the same (`fa_attention_causal` shares `fa_attention.hip`).
- Library kernels that are templates are instantiated by replacing the template parameters with `#define`s /
  `typedef`s of the values the launcher picks; batch loops, `load_ptr_batch`, stride / offset / increment
  arguments of rocBLAS are dropped (non-batched, unit increment, zero offset). Arguments that the library
  passes at run time for a contiguous tensor (row strides of FlashInfer / vLLM / MIOpen batch norm) are kept
  and set by the manifest.
- `launch` in the manifest is the launcher's grid / block / dynamic LDS for float32 on gfx950 (wave64,
  256 compute units; the two launchers that size the grid from the device, `mo_adam` and `mo_bn_infer`, have
  the 256 written into the launch expression).
- `shapes` are the battery sizes (not multiples of the block sizes; `dynamic` symbols are also run at 1,
  v - 1, v + 1 and a larger value). The kernels are valid at every size the battery uses, but a library
  launcher may pick another variant at the small ones (noted in the tables); `bench_shapes` are in the
  regime of the variant extracted.
- Tags: `llm`, the source (`rocblas`, `miopen`, `flashinfer`, `vllm`, `port`) and a class.
- `refs.py`: sums in float64; a value the kernel rounds to float32 before it is amplified (a scalar
  argument, `mean + eps`, a `pow`) is rounded the same way. A `<name>_scale` function gives the magnitude
  that the `cond` tolerance is relative to when evaluating the reference on |inputs| would cancel
  (`c*y - s*x`); see `agc/runtime/reference.py`.

## Extracted kernels

### rocBLAS (`projects/rocblas/library/src`, helpers in `rocblas_common.h`)

Common to all: `T = float`, non-batched (the `for(batch ...)` loop over `c_YZ_grid_launch_limit` and
`load_ptr_batch` / `load_scalar` removed), scalars by value (host pointer mode), unit increments, zero
offsets. Block sizes are `ROCBLAS_*_NB` of `library/include/internal/rocblas_block_sizes.h`.

| Kernel | Upstream file | Upstream function | Instantiation, launch |
|---|---|---|---|
| `rb_copy` | `blas1/rocblas_copy_kernels.hpp` | `rocblas_scopy_2_kernel` | `DIM_X = 256`; the float, inc-1 branch of `rocblas_internal_copy_launcher`: grid `(n-1)/(2 NB)+1`, block 256 |
| `rb_scal` | `blas1/rocblas_scal_kernels.hpp` | `rocblas_sscal_2_kernel` | `DIM_X = 256`, `Tex = Ta = float`; grid `(n-1)/(2 NB)+1`, block 256 |
| `rb_axpy` | `blas1/rocblas_axpy_kernels.hpp` | `rocblas_saxpy_2_kernel` | `NB = 256`, `Tex = float`; the branch for float, unit inc, `batch_count <= 8192`; grid `(n-1)/(2 NB)+1`, block 256 |
| `rb_swap` | `blas1/rocblas_swap_kernels.hpp` | `rocblas_sswap_2_kernel`, `rocblas_swap_vals` | `DIM_X = 256`; grid `(n-1)/(2 NB)+1`, block 256 |
| `rb_rot` | `blas1/rocblas_rot_kernels.hpp` | `rocblas_rot_kernel`, `rocblas_rot_kernel_calc` (real) | `NB = 512`, `Tex = float`; grid `(n-1)/NB+1`, block 512 |
| `rb_dot` | `blas1/rocblas_dot_kernels.hpp`, `blas1/rocblas_reduction.hpp` | `rocblas_dot_kernel_inc1<ONE_BLOCK = false>`, `rocblas_dot_save_sum`, `rocblas_dot_block_reduce`, `rocblas_wavefront_reduce` | `NB = 512`, `WIN = 4`, `CONJ = false`; first stage only: per-block partial sums in `workspace` (when the grid is one block the sum goes to `out`, as upstream). Launcher's last branch (x != y, not gfx942, `n` above the one-block threshold 31000): grid `ceil(n / (NB WIN))`, block 512. The battery also runs sizes below 31000, where the library would launch `rocblas_dot_kernel_inc1by2<ONE_BLOCK = true>` |
| `rb_nrm2` | `blas1/rocblas_asum_nrm2_kernels.hpp`, `rocblas_asum_nrm2.hpp`, `fetch_template.hpp` | `rocblas_reduction_kernel_part1` with `FETCH = rocblas_fetch_nrm2<float>` (`fetch_abs2`) | `NB = 512`, `WIN = 4`; first stage only: per-block partial sums of squares. grid `ceil(n / (NB WIN))`, block 512 |
| `rb_gemvn` | `blas2/gemv_device.hpp` (launcher `blas2/rocblas_gemv_kernels.cpp`) | `rocblas_gemvn_kernel`, `rocblas_gemvn_kernel_calc` (variant for all types but double complex) | `DIM_X = 64`, `DIM_Y = 16`, `T_Index = rocblas_int`; the launcher's final branch for `transA = none` (not gfx906/908/90a/942/11xx/12xx, not "skinny m", not `n <= 128 && m >= 2048 n`): grid `(m-1)/(4 DIM_X)+1`, block (64, 16). `A` is column-major with `lda = m` (tensor `[n, m]`) |
| `rb_gemvt` | `blas2/gemv_device.hpp`, `blas1/reduction.hpp` | `rocblas_gemvt_kernel<CONJ = false>`, `rocblas_gemvt_kernel_calc`, `rocblas_sum_reduce` | `NB_X = 256`; the launcher's branch for float, transpose, not gfx908/942/10-12, grid not clamped: grid `n` (one block per column), block 256 |
| `rb_ger` | `blas2/rocblas_ger_kernels.hpp` | `rocblas_sger_kernel` | `DIM_X = 1024`; the launcher's branch for float, `m > 1024`, not gfx90a / gfx942: grid `n`, block 1024. The battery also runs `m <= 1024`, where the library launches `rocblas_ger_kernel` |

### MIOpen (`projects/miopen/src/kernels`, launch code in `projects/miopen/src/solver`, helpers in `miopen_common.h`)

Common to all: `-DMIOPEN_USE_FP32=1` (`FLOAT = FLOAT_ACCUM = float`). MIOpen passes build options as `-D`
macros; they are `#define`d at the top of each file. Global work sizes are converted to a grid as MIOpen's
HIP backend does (`g_wk / l_wk`).

| Kernel | Upstream file | Upstream function | Instantiation, launch |
|---|---|---|---|
| `mo_glu_fwd` | `MIOpenGLU.cpp` (`solver/glu/forward_glu.cpp`) | `GLUFwdContiguousDim0`, `GLUFwdContiguousKernel`, `sigmoid` | `IO_TYPE = float`; nothing removed. grid `ceil(N/256)`, block 256 |
| `mo_rope_fwd` | `MIOpenRoPE.cpp` (`solver/rope/forward_rope.cpp`) | `RoPEFwdContiguous`, `ropefwdcontiguous` | `INPUT_TYPE = OUTPUT_TYPE = float`; nothing removed. block 256; the solver passes the global size `output_numel` unrounded, the manifest launches `ceil(output_numel/256)` blocks |
| `mo_reduce_sum` | `MIOpenReduceSum.cpp`, `block_reduce.hpp`, `warp_reduce.hpp` (`solver/prelu/backward_prelu_single_weight.cpp`, phase 2) | `ReduceSumFLOATACCUM`, `block_reduce`, `block_reduce_warp<64>`, `warp_reduce` | `REDUCE_SIZE = 256`; nothing removed. One reduction level: `output[b]` = sum of 256 inputs. grid `ceil(N/256)`, block 256 |
| `mo_t5_layernorm` | `MIOpenT5LayerNorm.cpp` (`solver/layernorm/forward_t5layernorm.cpp`) | `T5LayernormFwdContiguous`, `t5layernormfwdcontiguous` | `LOCAL_SIZE = 256`, `MIOPEN_ELEMENTWISE_AFFINE_T5 = 4`, `MIOPEN_WEIGHT_BIAS_T5 = 5`; nothing removed. `mode = 1`, the value the solver passes for `MIOPEN_WEIGHT_BIAS_T5` (see Notes). grid `outer_size`, block 256 |
| `mo_active_fwd` | `MIOpenNeuron.cpp`, `activation_functions.hpp` (`solver/activ/fwd_0.cpp`) | `MIOpenActiveFwdLite`, `ActivationFunction`, `ActivationFunction_Leaky_ReLU` | Activation: **leaky ReLU** (`MIOPEN_NRN_OP_ID = 8`); packed tensor with a length that is a multiple of 4: `MIOPEN_READ_UNIT = 4`, `MIOPEN_READ_TYPE = float4`, `LOCAL_SIZE = 256`. Removed: `bot_offset` / `top_offset` (zero) and the other ten activations of the `if constexpr` chain. grid `ceil(len/4/256)`, block 256 |
| `mo_adam` | `MIOpenAdam.cpp` (`solver/adam/adam.cpp`) | `AdamContiguous`, `AdamInternal` | `PTYPE = CTYPE = float`; nothing removed. Plain Adam: `amsgrad = maximize = adamw = false`, `weight_decay = 0`. grid `4 * compute units = 1024` blocks of 256 (grid-stride loop) |
| `mo_bn_infer` | `MIOpenBatchNormFwdInferSpatial.cpp`, `bnorm_spatial_activation_functions.hpp`, `vector_types.hpp` (`solver/batchnorm/forward_inference.cpp`) | `MIOpenBatchNormFwdInferSpatialEst`, `BNFwdInferSpatialImpl`, `activation_op` (pass-through) | NCHW, `h*w` a multiple of 4: `MIO_BN_GRP0/1/2 = 1/256/1`, `MIO_LAYOUT_NHWC = 0`, `MIO_BN_VEC_SIZE = 4`, `MIOPEN_NRN_OP_ID = 0`; nothing removed. grid `(c, ceil(hw/4/256), min(max(1, 256*32*64 / (c*256*ceil(hw/4/256))), n))`, block (1, 256, 1) |
| `mo_prelu_bwd` | `MIOpenPReLU.cpp` (`solver/prelu/backward_prelu_single_weight.cpp`, phase 1) | `PReLUSWBackward`, `PReLUBackward<SingleWeight = true>` | `INPUT_TYPE = OUTPUT_TYPE = float`, `VIEW_DIMS = 5`. Removed: the four `tensor_view_t` arguments; for contiguous tensors `get_tensor_view_idx(tensor_layout_t(tv, gid)) == gid`, so the 5-D index decomposition and recomposition (integer divisions per element upstream) are replaced by `gid`. grid `ceil(N/256)`, block 256 |

`mo_bn_infer` and `mo_prelu_bwd` (and `rb_copy`, `rb_swap`, `rb_rot`, `rb_nrm2`, `rb_ger`) are not LLM
kernels in the narrow sense; they were extracted before the benchmark was focused on LLMs and are kept
because they pass.

### FlashInfer (`include/flashinfer`, helpers in `flashinfer_common.h`)

Common to all: `DType = float`. FlashInfer's kernels are CUDA; they compile as HIP with these substitutions:
the PTX inline-asm wrappers of `math.cuh` call the HIP function (`ex2.approx` -> `exp2f`, `lg2.approx` ->
`log2f`, `rsqrt.approx` -> `rsqrtf`, `tanh.approx` -> `tanhf`, `shfl.sync.bfly` -> `__shfl_xor`), `__expf` /
`__powf` / `__sincosf` / `__fdividef` are `expf` / `powf` / `sincosf` / a division, and the
`griddepcontrol` (programmatic dependent launch, sm_90) asm is removed. The kernels hard-code 32-lane
warps (`warp_size = 32`, `blockDim.x = 32`); on wave64 a wavefront holds two such rows and the 32-lane
butterfly reductions stay inside a row, so the code is unchanged.

| Kernel | Upstream file | Upstream function | Instantiation, launch |
|---|---|---|---|
| `fi_rmsnorm` | `norm.cuh` | `RMSNormKernel` (launcher `RMSNorm`) | `VEC_SIZE = gcd(16/sizeof(float), d) = 4` (d a multiple of 4), `weight_bias = 0`; grid `batch`, block `(32, ceil(min(1024, d/4)/32))`, dynamic LDS `4 * num_warps` bytes |
| `fi_fused_add_rmsnorm` | `norm.cuh` | `FusedAddRMSNormKernel` (launcher `FusedAddRMSNorm`) | as above; dynamic LDS `4 * (ceil(num_warps/4)*4 + d)` bytes (the row is staged in LDS) |
| `fi_silu_and_mul` | `activation.cuh`, `flashinfer/jit/activation.py` | `activation::act_and_mul_kernel` with `silu` | `vec_size = 4`; grid `num_tokens`, block `min(d/4, 256)`. The JIT launcher uses this kernel when there are at least 2 blocks per SM (`num_tokens >= 2 * num_sms`) and `act_and_mul_split_kernel` below that; the bench shape is in the first regime, the battery sizes are not |
| `fi_gelu_tanh_and_mul` | same | `activation::act_and_mul_kernel` with `gelu_tanh` | same |
| `fi_rope` | `pos_enc.cuh` | `BatchQKApplyRotaryPosIdsHeadParallelismKernel<interleave = false, head_dim = 128>`, `vec_apply_llama_rope_cos_sin` (launcher `BatchQKApplyRotaryPosIds`) | `vec_size = 4`, `bdx = 32`, `bdy = 4`, `IdType = int32_t`; `smooth_a = smooth_b = 0`, `rope_scale = 1`, `rope_theta = 1e4`. grid `(ceil(nnz/4), num_qo_heads + num_kv_heads)`, block (32, 4). q and k are both rotated (`blockIdx.y` selects a head of q or of k). The launcher picks this kernel when the positions do not fill the device and `BatchQKApplyRotaryPosIdsKernel` otherwise, from CUDA occupancy queries that have no counterpart here. The interleave branches are dead |
| `fi_merge_state` | `attention/cascade.cuh` | `MergeStateKernel` (launcher `MergeState`, `HEAD_DIM = 128`) | `vec_size = max(4, 128/32) = 4`; grid `seq_len`, block `(32, num_heads)`; nothing removed |
| `fi_merge_state_in_place` | `attention/cascade.cuh` | `MergeStateInPlaceKernel` (launcher `MergeStateInPlace`) | as above, with a mask |
| `fi_merge_states` | `attention/cascade.cuh`, `attention/state.cuh` | `MergeStatesKernel`, `state_t` (launcher `MergeStates`, branch `num_index_sets < seq_len`) | as above; `num_index_sets = 4` (0, 1 and n > 1 are distinct paths; the battery varies it) |

### vLLM (`csrc`, helpers in `vllm_common.h`)

Common to all: `scalar_t = float`, the ROCm configuration (`USE_ROCM`: hipCUB as `cub`, `WARP_SIZE = 64`).
hipCUB is the ROCm installation's (`/opt/rocm/include/hipcub`), as in a vLLM ROCm build.

| Kernel | Upstream file | Upstream function | Instantiation, launch |
|---|---|---|---|
| `vl_rms_norm` | `layernorm_kernels.cu`, `quantization/vectorization_utils.cuh` | `vllm::rms_norm_kernel<VEC_SIZE = 4, NUM_DIMS = 2, HasWeight = true>`, `vectorize_read_with_alignment`, `cub::BlockReduce<float, 1024>` | 1-D weight (`weight_stride = 0`); nothing removed. grid `num_tokens`, block `min(hidden/4, 256)` (the launcher uses up to 1024 threads when `num_tokens < 256`; the bench shape has more tokens) |
| `vl_fused_add_rms_norm` | `layernorm_kernels.cu` | `vllm::fused_add_rms_norm_kernel<width = 0, HasWeight = true>` (the generic kernel; the packed one exists for fp16 / bf16 only) | nothing removed. grid `num_tokens`, block `min(hidden, 256)` (same remark) |
| `vl_rotary_embedding` | `pos_encoding_kernels.cu` | `vllm::rotary_embedding_kernel<IS_NEOX = true>`, `apply_rotary_embedding`, `apply_token_rotary_embedding` | `cache_t = float`, in place, `rope_dim_offset = 0`, `inverse = false`; nothing removed. grid `num_tokens`, block `min(num_heads * head_size / 2, 512)` |
| `vl_moe_align` | `moe/moe_align_sum_kernels.cu` | `vllm::moe::moe_align_block_size_kernel<int32_t>`, `_moe_align_block_size`, `get_local_expert_id`, `cub::BlockScan<int32_t, 1024>` | no expert map; nothing removed. The count / align kernel of `moe_align_block_size` (not the small-batch branch): 2 blocks of 1024 threads, dynamic LDS `4 * round_up(num_experts, 64)` bytes. Integer outputs, compared exactly |

## Ports

Written for this benchmark, straightforwardly (clear loops, a sensible block size, LDS where natural), not
hand-tuned and not deliberately slow. They are original code; the references define the semantics only.

| Kernel | Reference | What it computes, shapes, launch |
|---|---|---|
| `fa_attention`, `fa_attention_causal` | FlashAttention (Dao et al., 2022, Algorithm 1); [Dao-AILab/flash-attention](https://github.com/Dao-AILab/flash-attention) | One head: `out[i] = softmax_j(scale * Q[i].K[j]) V[j]` and `lse[i]`, visiting K / V in tiles of 64 keys with the online-softmax recurrence (running max and sum, rescaling the partial output). `Q [NQ, 64]`, `K, V [NK, 64]`, `scale = 1/8`. One block of 64 threads per query row. The causal manifest (same source, `causal = 1`) attends to keys `0..i` |
| `attn_decode` | FlashInfer `single_decode_with_kv_cache` (`include/flashinfer/attention/decode.cuh`, `SingleDecodeWithKVCacheKernel`) | Decode-step attention of one query over a contiguous KV cache with grouped query heads, FlashInfer's layouts: `q [Hq, 128]`, `k, v [S, Hkv, 128]`, `o [Hq, 128]`, `lse [Hq]` (natural log; FlashInfer's is base 2). One block of 128 threads per query head. FlashInfer's kernel (cp.async staging, permuted shared memory, variant templates) could not be extracted without rewriting most of it |
| `mla_decode` | [deepseek-ai/FlashMLA](https://github.com/deepseek-ai/FlashMLA), `flash_mla_with_kvcache` (dense decoding: `q [batch, 1, heads, 576]`, cache rows of 576, `head_dim_v = 512`, `softmax_scale = 576^-0.5`) | DeepSeek MLA decode step: every head of every sequence attends to the sequence's latent cache shared by all heads; the score uses all 576 dims (512 latent + 64 RoPE), the output averages the first 512. `q [B, H, 576]`, `kv_cache [B, S, 576]` (contiguous, one length for all sequences; no paging), `out [B, H, 512]`, `lse [B, H]`, float32 (FlashMLA is bf16). One block of 256 threads per (head, sequence) |
| `kda_step` | [fla-org/flash-linear-attention](https://github.com/fla-org/flash-linear-attention), `fla/ops/kda/naive.py`, `naive_recurrent_kda` (MIT) | One time step of Kimi Delta Attention for a batch of heads, the loop body of the reference: `S = S * exp(g)[:, None]`, `S = S + (beta k)[:, None] (v - k^T S)`, `o = (scale q)^T S`. `S [H, dk, dv]` in place, `g, k, q [H, dk]`, `v, o [H, dv]`, `beta [H]`. One block of 128 threads per head, thread = column of `S` |
| `moe_gate_topk` | vLLM `topk_softmax` (`csrc/moe/topk_softmax_kernels.cu`, `topkGating` with softmax scoring) | Softmax over the expert logits of each token, then the top-k experts with their probabilities in descending order (ties: lower index). `logits [T, E]`, `weights [T, 8]`, `indices [T, 8]` (exact). One thread per token. vLLM's kernel is a ~300-line template over values-per-thread / bytes-per-load / warp layouts and was not extracted |

`attn_port.h` holds the online-softmax row shared by the three attention ports.

## Not included

| Candidate | Reason |
|---|---|
| rocSPARSE `ellmv`, `csrmv` | dropped when the benchmark was focused on LLM kernels |
| FlashInfer `GemmaRMSNorm` / `GemmaFusedAddRMSNorm` | the same kernels as `fi_rmsnorm` / `fi_fused_add_rmsnorm` launched with `weight_bias = 1` |
| FlashInfer `AppendPagedKVCacheKernel` (`page.cuh`) | needs distinct (batch index, position) pairs; the existing `init` kinds produce random indices, which collide, and colliding appends race |
| FlashInfer `sampling.cuh` (`SamplingFromProb`, `TopPSamplingFromProb`) | built on `cub::BlockScan` / `BlockReduce` over device structs and on comparisons of a float32 prefix sum with the uniform sample, whose outcome at a threshold depends on the summation order; not expressible as a reference with an honest tolerance |
| FlashInfer `decode.cuh` `SingleDecodeWithKVCacheKernel` | see the port `attn_decode` |
| vLLM `silu_and_mul` (`activation_kernels.cu`) | the scalar ancestor of FlashInfer's `act_and_mul_kernel` (same one-block-per-token loop, without the vector loads); not extracted |
| vLLM `topk_softmax` | see the port `moe_gate_topk` |
| vLLM `count_and_sort_expert_tokens_kernel` | the order within an expert depends on the `atomicAdd` race |

## Notes

- **Tolerances.** Copies, swaps and single multiplications are compared exactly or to 1e-6 relative.
  Sums use `cond` (a multiple of the float32 unit roundoff times the sum of the magnitudes of the terms).
  Kernels that call libm use `rtol` 1e-4 to 1e-3.
- **`fi_rope`**: the kernel computes the frequencies with `powf` and multiplies them by the position, so one
  ulp of `powf` becomes `pos * 6e-8` radians. amdclang's `powf` is not always correctly rounded (nor is
  NumPy's float32 `power`, which is why the reference rounds a float64 `pow`). Positions are below 256 and
  `cond = 4e-5` (256 ulp) covers it; the reference is otherwise exact.
- **Softmax ports**: `Q` and `K` are pinned to the `normal` distribution (`init`). With scores of 1e12 (the
  `large_exponent` distribution) a softmax is an arg-max whose winner depends on the rounding of a
  64-term dot product; no tolerance is honest there. `V` uses every distribution.
- **`mo_bn_infer`**: the bias is small integers (`init`), so that the default tolerance is a rigorous bound
  (the cancellation in `scale * xhat + bias` is then below `atol`).
- **`mo_adam`**: `exp_avg_sq_in` is in {0, 1}: the kernel has `__builtin_assume(exp_avg_sq >= 0 &&
  exp_avg_sq <= 1)`, so other inputs are undefined behaviour upstream.
- **`kda_step`**: `g` (log-space decay) is in {-3..0}.
- **Upstream quirks seen while extracting** (kept as they are):
  - MIOpen T5 layer norm: the solver passes `static_cast<bool>(mode % 2)` (0 or 1) while the kernel tests
    `mode == MIOPEN_ELEMENTWISE_AFFINE_T5` (4); the test is never true and `weight` is always read.
  - MIOpen RoPE passes an unrounded global work size (`output_numel`), which the cooperative-launch path of
    `src/hipoc/hipoc_kernel.cpp` (`WORKAROUND_SWDEV_448157`) rejects when it is not a multiple of 256.
  - rocBLAS `gemvn`: in the tail (n not a multiple of 64) the kernel reads `A[ind + 0]` (column 0)
    multiplied by a zero `res_x` for the columns past `n`; a non-finite value in column 0 would turn
    into NaN.

## Running

```
.venv/bin/agc check bench/llm/<name>.json     # the battery against refs.py, amdclang's build
.venv/bin/agc bench bench/llm/<name>.json     # timing at bench_shapes
```
