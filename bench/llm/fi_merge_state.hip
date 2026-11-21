// From FlashInfer (flashinfer-ai/flashinfer @ 5cd7ab08e2a7, Apache-2.0; see LICENSES.md and README.md).
// MergeStateKernel<vec_size = 4, DTypeIn = float, DTypeO = float>, include/flashinfer/attention/cascade.cuh
// (the launcher MergeState for HEAD_DIM = 128: vec_size = max(16 / sizeof(float), 128 / 32) = 4,
// blockDim = (HEAD_DIM / vec_size, num_heads) = (32, num_heads), one block per position). Nothing removed.
#include "flashinfer_common.h"

using namespace flashinfer;
#define vec_size 4

extern "C" __global__ void fi_merge_state(float* __restrict__ v_a, float* __restrict__ s_a,
                                          float* __restrict__ v_b, float* __restrict__ s_b,
                                          float* __restrict__ v_merged, float* __restrict__ s_merged,
                                          uint32_t num_heads, uint32_t head_dim) {
  uint32_t tx = threadIdx.x, ty = threadIdx.y;
  uint32_t pos = blockIdx.x;
  uint32_t head_idx = ty;

  float s_a_val = s_a[pos * num_heads + head_idx];
  float s_b_val = s_b[pos * num_heads + head_idx];
  float s_max = max(s_a_val, s_b_val);
  // max() drops the NaN from merging two empty states ((-inf) - (-inf)); the
  // d_sum guard keeps their merged output zero instead of 0/0 = NaN.
  s_a_val = math::ptx_exp2(max(s_a_val - s_max, -math::inf));
  s_b_val = math::ptx_exp2(max(s_b_val - s_max, -math::inf));
  float d_sum = s_a_val + s_b_val;
  float a_scale = (d_sum > 0.f) ? s_a_val / d_sum : 0.f;
  float b_scale = (d_sum > 0.f) ? s_b_val / d_sum : 0.f;
  vec_t<float, vec_size> v_a_vec, v_b_vec, v_merged_vec;
  v_a_vec.cast_load(v_a + (pos * num_heads + head_idx) * head_dim + tx * vec_size);
  v_b_vec.cast_load(v_b + (pos * num_heads + head_idx) * head_dim + tx * vec_size);
#pragma unroll
  for (uint32_t i = 0; i < vec_size; ++i) {
    v_merged_vec[i] = a_scale * v_a_vec[i] + b_scale * v_b_vec[i];
  }
  v_merged_vec.cast_store(v_merged + (pos * num_heads + head_idx) * head_dim + tx * vec_size);
  if (tx == 0 && s_merged != nullptr) {
    s_merged[pos * num_heads + head_idx] = math::ptx_log2(d_sum) + s_max;
  }
}
