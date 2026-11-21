// From vLLM (vllm-project/vllm @ efb6ed2fe36a, Apache-2.0; see LICENSES.md and README.md).
// vllm::moe::moe_align_block_size_kernel<scalar_t = int32_t> + _moe_align_block_size + get_local_expert_id,
// csrc/moe/moe_align_sum_kernels.cu: the count / align kernel of moe_align_block_size (the launcher's
// non-small-batch branch: 2 blocks of 1024 threads, block 0 counts the tokens of each expert and writes
// the padded cumulative offsets and the expert id of every block, block 1 fills sorted_token_ids with
// numel; count_and_sort_expert_tokens_kernel, launched after it, is not part of this benchmark because
// the order it writes within an expert depends on the atomicAdd race).
// ROCm configuration: WARP_SIZE = 64 (csrc/core/cuda_compat.h), hipCUB BlockScan (csrc/cub_helpers.h).
// Nothing removed.
#include "vllm_common.h"

#define WARP_SIZE 64
#define CEILDIV(x, y) (((x) + (y) - 1) / (y))

namespace vllm {
namespace moe {

template <typename scalar_t>
__device__ __forceinline__ int get_local_expert_id(
    size_t idx, const scalar_t* __restrict__ topk_ids,
    int32_t* __restrict__ expert_map, int32_t num_experts,
    bool has_expert_map) {
  int expert_id = topk_ids[idx];
  if (expert_id >= num_experts || expert_id < 0) {
    return -1;
  }
  if (has_expert_map) {
    expert_id = expert_map[expert_id];
  }
  return expert_id;
}

template <typename scalar_t>
__device__ void _moe_align_block_size(
    const scalar_t* __restrict__ topk_ids,
    int32_t* __restrict__ sorted_token_ids, int32_t* __restrict__ expert_ids,
    int32_t* __restrict__ total_tokens_post_pad,
    int32_t* __restrict__ expert_map, int32_t num_experts,
    int32_t padded_num_experts, int32_t experts_per_warp, int32_t block_size,
    size_t numel, int32_t* __restrict__ cumsum, int32_t max_num_tokens_padded,
    int32_t max_num_m_blocks, int32_t model_offset, int32_t inactive_expert_id,
    int32_t topk_num, int32_t* token_mask, bool has_expert_map) {
  extern __shared__ int32_t shared_counts[];

  // Compute input buffer offsets. Typically these will all be 0, except when
  // using Multi LoRA.
  int sorted_token_ids_offset = max_num_tokens_padded * model_offset;
  int expert_ids_offset = max_num_m_blocks * model_offset;
  int cumsum_offset = (num_experts + 1) * model_offset;

  // Use separate threadblocks to fill sorted_token_ids.
  // This is safe since the current kernel does not use sorted_token_ids.
  if (blockIdx.x % 2) {
    // Initialize sorted_token_ids with numel
    for (size_t it = threadIdx.x; it < max_num_tokens_padded;
         it += blockDim.x) {
      sorted_token_ids[sorted_token_ids_offset + it] = numel;
    }
    return;
  }

  const int warp_id = threadIdx.x / WARP_SIZE;
  const int my_expert_start = warp_id * experts_per_warp;

  for (int i = 0; i < experts_per_warp; ++i) {
    if (my_expert_start + i < padded_num_experts) {
      shared_counts[warp_id * experts_per_warp + i] = 0;
    }
  }

  __syncthreads();

  const size_t tid = threadIdx.x;
  const size_t stride = blockDim.x;

  for (size_t i = tid; i < numel; i += stride) {
    if (int expert_id = get_local_expert_id(i, topk_ids, expert_map,
                                            num_experts, has_expert_map);
        expert_id != -1) {
      int warp_idx = expert_id / experts_per_warp;
      int expert_offset = expert_id % experts_per_warp;
      int mask = token_mask == nullptr ? 1 : token_mask[i / topk_num];
      atomicAdd(&shared_counts[warp_idx * experts_per_warp + expert_offset],
                mask);
    }
  }

  __syncthreads();

  // Compute prefix sum over token counts per expert
  using BlockScan = cub::BlockScan<int32_t, 1024>;
  __shared__ typename BlockScan::TempStorage temp_storage;

  int expert_count = 0;
  int expert_id = threadIdx.x;
  if (expert_id < num_experts) {
    int warp_idx = expert_id / experts_per_warp;
    int expert_offset = expert_id % experts_per_warp;
    expert_count = shared_counts[warp_idx * experts_per_warp + expert_offset];
    expert_count = CEILDIV(expert_count, block_size) * block_size;
  }

  int cumsum_val;
  BlockScan(temp_storage).ExclusiveSum(expert_count, cumsum_val);
  if (expert_id <= num_experts) {
    cumsum[cumsum_offset + expert_id] = cumsum_val;
  }

  if (expert_id == num_experts) {
    total_tokens_post_pad[model_offset] = cumsum_val;
  }

  __syncthreads();

  if (threadIdx.x < num_experts) {
    for (int i = cumsum[cumsum_offset + threadIdx.x];
         i < cumsum[cumsum_offset + threadIdx.x + 1]; i += block_size) {
      expert_ids[expert_ids_offset + i / block_size] = threadIdx.x;
    }
  }

  // Fill remaining expert_ids with -1
  const size_t fill_start_idx =
      cumsum[cumsum_offset + num_experts] / block_size + threadIdx.x;
  for (size_t i = fill_start_idx; i < max_num_m_blocks; i += blockDim.x) {
    expert_ids[expert_ids_offset + i] = inactive_expert_id;
  }
}

}  // namespace moe
}  // namespace vllm

extern "C" __global__ void vl_moe_align(
    const int32_t* __restrict__ topk_ids,
    int32_t* __restrict__ sorted_token_ids, int32_t* __restrict__ expert_ids,
    int32_t* __restrict__ total_tokens_post_pad,
    int32_t* __restrict__ expert_map, int32_t num_experts,
    int32_t padded_num_experts, int32_t experts_per_warp, int32_t block_size,
    size_t numel, int32_t* __restrict__ cumsum, int32_t max_num_tokens_padded,
    int32_t topk_num, bool has_expert_map) {
  vllm::moe::_moe_align_block_size(
      topk_ids, sorted_token_ids, expert_ids, total_tokens_post_pad, expert_map,
      num_experts, padded_num_experts, experts_per_warp, block_size, numel,
      cumsum, max_num_tokens_padded, CEILDIV(max_num_tokens_padded, block_size),
      0, -1, topk_num, nullptr, has_expert_map);
}
