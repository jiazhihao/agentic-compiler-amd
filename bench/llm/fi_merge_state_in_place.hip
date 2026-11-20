// From FlashInfer (flashinfer-ai/flashinfer @ 5cd7ab08e2a7, Apache-2.0; see LICENSES.md and README.md).
// MergeStateInPlaceKernel<vec_size = 4, DType = float>, include/flashinfer/attention/cascade.cuh
// (the launcher MergeStateInPlace for HEAD_DIM = 128: vec_size = 4, blockDim = (32, num_heads), one block
// per position; a non-null mask). Nothing removed.
#include "flashinfer_common.h"

using namespace flashinfer;
#define vec_size 4

extern "C" __global__ void fi_merge_state_in_place(float* __restrict__ v, float* __restrict__ s,
                                                   float* __restrict__ v_other, float* __restrict__ s_other,
                                                   uint8_t* __restrict__ mask, uint32_t num_heads,
                                                   uint32_t head_dim) {
  uint32_t pos = blockIdx.x;

  if (mask != nullptr && mask[pos] == 0) return;

  uint32_t tx = threadIdx.x, ty = threadIdx.y;
  uint32_t head_idx = ty;

  float s_val = s[pos * num_heads + head_idx];
  float s_other_val = s_other[pos * num_heads + head_idx];
  float s_max = max(s_val, s_other_val);
  // max() drops the NaN from merging two empty states ((-inf) - (-inf)); the
  // d_sum guard keeps their merged output zero instead of 0/0 = NaN.
  s_val = math::ptx_exp2(max(s_val - s_max, -math::inf));
  s_other_val = math::ptx_exp2(max(s_other_val - s_max, -math::inf));
  float d_sum = s_val + s_other_val;
  float scale = (d_sum > 0.f) ? s_val / d_sum : 0.f;
  float other_scale = (d_sum > 0.f) ? s_other_val / d_sum : 0.f;
  vec_t<float, vec_size> v_vec, v_other_vec;
  v_vec.cast_load(v + (pos * num_heads + head_idx) * head_dim + tx * vec_size);
  v_other_vec.cast_load(v_other + (pos * num_heads + head_idx) * head_dim + tx * vec_size);
#pragma unroll
  for (uint32_t i = 0; i < vec_size; ++i) {
    v_vec[i] = scale * v_vec[i] + other_scale * v_other_vec[i];
  }
  v_vec.cast_store(v + (pos * num_heads + head_idx) * head_dim + tx * vec_size);
  if (tx == 0 && s != nullptr) {
    s[pos * num_heads + head_idx] = math::ptx_log2(d_sum) + s_max;
  }
}
