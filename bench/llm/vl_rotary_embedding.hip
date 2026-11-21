// From vLLM (vllm-project/vllm @ efb6ed2fe36a, Apache-2.0; see LICENSES.md and README.md).
// vllm::rotary_embedding_kernel<scalar_t = float, cache_t = float, IS_NEOX = true> + apply_rotary_embedding
// + apply_token_rotary_embedding, csrc/pos_encoding_kernels.cu (the launcher rotary_embedding: one block
// per token, block = min(num_heads * head_size / 2, 512); query and key rotated in place).
// Nothing removed; VLLM_LDG is __ldg as in csrc/core/cuda_compat.h.
#include <hip/hip_runtime.h>
#include <cstdint>

#define VLLM_LDG(arg) __ldg(arg)

namespace vllm {

template <typename scalar_t, typename cache_t, bool IS_NEOX>
inline __device__ void apply_token_rotary_embedding(
    scalar_t* __restrict__ arr, const cache_t* __restrict__ cos_ptr,
    const cache_t* __restrict__ sin_ptr, int rot_offset, int embed_dim,
    const bool inverse) {
  int x_index, y_index;
  float cos_f, sin_f;
  if (IS_NEOX) {
    x_index = rot_offset;
    y_index = embed_dim + rot_offset;
    cos_f = static_cast<float>(VLLM_LDG(cos_ptr + x_index));
    sin_f = static_cast<float>(VLLM_LDG(sin_ptr + x_index));
  } else {
    x_index = 2 * rot_offset;
    y_index = 2 * rot_offset + 1;
    cos_f = static_cast<float>(VLLM_LDG(cos_ptr + x_index / 2));
    sin_f = static_cast<float>(VLLM_LDG(sin_ptr + x_index / 2));
  }
  if (inverse) {
    sin_f = -sin_f;
  }

  const float x_f = static_cast<float>(arr[x_index]);
  const float y_f = static_cast<float>(arr[y_index]);
  arr[x_index] = static_cast<scalar_t>(x_f * cos_f - y_f * sin_f);
  arr[y_index] = static_cast<scalar_t>(y_f * cos_f + x_f * sin_f);
}

template <typename scalar_t, typename cache_t, bool IS_NEOX>
inline __device__ void apply_rotary_embedding(
    scalar_t* __restrict__ query, scalar_t* __restrict__ key,
    const cache_t* cache_ptr, const int head_size, const int num_heads,
    const int num_kv_heads, const int rot_dim, const int token_idx,
    const int64_t query_stride, const int64_t key_stride,
    const int64_t head_stride, const int64_t rope_dim_offset,
    const bool inverse) {
  const int embed_dim = rot_dim / 2;
  const cache_t* cos_ptr = cache_ptr;
  const cache_t* sin_ptr = cache_ptr + embed_dim;

  const int nq = num_heads * embed_dim;
  for (int i = threadIdx.x; i < nq; i += blockDim.x) {
    const int head_idx = i / embed_dim;
    const int64_t token_head =
        token_idx * query_stride + head_idx * head_stride + rope_dim_offset;
    const int rot_offset = i % embed_dim;
    apply_token_rotary_embedding<scalar_t, cache_t, IS_NEOX>(
        query + token_head, cos_ptr, sin_ptr, rot_offset, embed_dim, inverse);
  }

  if (key != nullptr) {
    const int nk = num_kv_heads * embed_dim;
    for (int i = threadIdx.x; i < nk; i += blockDim.x) {
      const int head_idx = i / embed_dim;
      const int64_t token_head =
          token_idx * key_stride + head_idx * head_stride + rope_dim_offset;
      const int rot_offset = i % embed_dim;
      apply_token_rotary_embedding<scalar_t, cache_t, IS_NEOX>(
          key + token_head, cos_ptr, sin_ptr, rot_offset, embed_dim, inverse);
    }
  }
}

}  // namespace vllm

extern "C" __global__ void vl_rotary_embedding(
    const int64_t* __restrict__ positions,  // [num_tokens]
    float* __restrict__ query,              // [num_tokens, num_heads, head_size]
    float* __restrict__ key,                // [num_tokens, num_kv_heads, head_size]
    const float* __restrict__ cos_sin_cache,  // [max_position, rot_dim]
    const int rot_dim, const int64_t query_stride, const int64_t key_stride,
    const int64_t head_stride, const int num_heads, const int num_kv_heads,
    const int head_size, const int64_t rope_dim_offset, const bool inverse) {
  const int token_idx = blockIdx.x;
  int64_t pos = positions[token_idx];
  const float* cache_ptr = cos_sin_cache + pos * rot_dim;

  vllm::apply_rotary_embedding<float, float, true>(
      query, key, cache_ptr, head_size, num_heads, num_kv_heads, rot_dim,
      token_idx, query_stride, key_stride, head_stride, rope_dim_offset,
      inverse);
}
