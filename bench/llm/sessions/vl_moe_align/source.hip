#include "vllm_common.h"

#define WARP_SIZE 64
#define CEILDIV(x, y) (((x) + (y) - 1) / (y))

typedef int32_t v4i __attribute__((vector_size(16), aligned(4)));

namespace vllm {
namespace moe {

// has_expert_map == false: ids outside [0, num_experts) are clamped to a dummy slot
// (index >= num_experts, never read back), so the add needs no lane mask.
__device__ __forceinline__ void cnt(int expert_id, int32_t* shared_counts, uint32_t dummy) {
  uint32_t k = (uint32_t)expert_id;
  k = k < dummy ? k : dummy;
  atomicAdd(&shared_counts[k], 1);
}
__device__ __forceinline__ void cntv(v4i x, int32_t* shared_counts, uint32_t dummy) {
  cnt(x[0], shared_counts, dummy);
  cnt(x[1], shared_counts, dummy);
  cnt(x[2], shared_counts, dummy);
  cnt(x[3], shared_counts, dummy);
}
__device__ __forceinline__ void cnt_map(int expert_id, int32_t* shared_counts,
    int32_t* __restrict__ expert_map, uint32_t ne) {
  if ((uint32_t)expert_id >= ne) return;
  expert_id = expert_map[expert_id];
  if (expert_id == -1) return;
  atomicAdd(&shared_counts[expert_id], 1);
}

template <typename scalar_t>
__device__ __forceinline__ void _moe_align_block_size(
    const scalar_t* __restrict__ topk_ids,
    int32_t* __restrict__ sorted_token_ids, int32_t* __restrict__ expert_ids,
    int32_t* __restrict__ total_tokens_post_pad,
    int32_t* __restrict__ expert_map, int32_t num_experts,
    int32_t padded_num_experts, int32_t experts_per_warp, int32_t block_size,
    size_t numel, int32_t* __restrict__ cumsum, int32_t max_num_tokens_padded,
    int32_t max_num_m_blocks, int32_t inactive_expert_id,
    int32_t topk_num, bool has_expert_map) {
  extern __shared__ int32_t shared_counts[];

  if (blockIdx.x != 0) {
    size_t base = ((size_t)(blockIdx.x - 1) * blockDim.x + threadIdx.x) * 4;
    size_t lim = max_num_tokens_padded < 0 ? 0 : (size_t)max_num_tokens_padded;
    int32_t val = (int32_t)numel;
    if (base + 4 <= lim) {
      v4i v = {val, val, val, val};
      *(v4i*)(sorted_token_ids + base) = v;
    } else {
      for (size_t it = base; it < lim; ++it) sorted_token_ids[it] = val;
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
  const uint32_t ne = num_experts < 0 ? 0u : (uint32_t)num_experts;
  const uint32_t pe = padded_num_experts < 0 ? 0u : (uint32_t)padded_num_experts;
  const uint32_t dummy = ne > pe ? ne : pe;

  if (!has_expert_map) {
    const size_t nvec = numel / 4;
    const v4i* vp = (const v4i*)topk_ids;
    size_t v = tid;
    for (; v + 7 * stride < nvec; v += 8 * stride) {
      v4i a = vp[v];
      v4i b = vp[v + stride];
      v4i c = vp[v + 2 * stride];
      v4i d = vp[v + 3 * stride];
      v4i e = vp[v + 4 * stride];
      v4i f = vp[v + 5 * stride];
      v4i g = vp[v + 6 * stride];
      v4i h = vp[v + 7 * stride];
      cntv(a, shared_counts, dummy);
      cntv(b, shared_counts, dummy);
      cntv(c, shared_counts, dummy);
      cntv(d, shared_counts, dummy);
      cntv(e, shared_counts, dummy);
      cntv(f, shared_counts, dummy);
      cntv(g, shared_counts, dummy);
      cntv(h, shared_counts, dummy);
    }
    for (; v < nvec; v += stride) {
      v4i a = vp[v];
      cntv(a, shared_counts, dummy);
    }
    for (size_t i = nvec * 4 + tid; i < numel; i += stride) {
      cnt(topk_ids[i], shared_counts, dummy);
    }
  } else {
    for (size_t i = tid; i < numel; i += stride) {
      cnt_map(topk_ids[i], shared_counts, expert_map, ne);
    }
  }

  __syncthreads();

  using BlockScan = cub::BlockScan<int32_t, 1024>;
  __shared__ typename BlockScan::TempStorage temp_storage;

  int expert_count = 0;
  int expert_id = threadIdx.x;
  if (expert_id < num_experts) {
    expert_count = shared_counts[expert_id];
    expert_count = CEILDIV(expert_count, block_size) * block_size;
  }

  int cumsum_val;
  BlockScan(temp_storage).ExclusiveSum(expert_count, cumsum_val);
  if (expert_id <= num_experts) {
    cumsum[expert_id] = cumsum_val;
  }

  if (expert_id == num_experts) {
    total_tokens_post_pad[0] = cumsum_val;
  }

  __syncthreads();

  if (threadIdx.x < num_experts) {
    int c0 = cumsum[threadIdx.x];
    int c1 = cumsum[threadIdx.x + 1];
    int n0 = c0 / block_size;
    for (int i = c0; i < c1; i += block_size, ++n0) {
      expert_ids[n0] = threadIdx.x;
    }
  }

  const size_t fill_start_idx =
      cumsum[num_experts] / block_size + threadIdx.x;
  for (size_t i = fill_start_idx; i < max_num_m_blocks; i += blockDim.x) {
    expert_ids[i] = inactive_expert_id;
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
      -1, topk_num, has_expert_map);
}
