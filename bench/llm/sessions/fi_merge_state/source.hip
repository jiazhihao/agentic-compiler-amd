#include "flashinfer_common.h"

using namespace flashinfer;
#define vec_size 4

extern "C" __global__ void fi_merge_state(float* __restrict__ v_a, float* __restrict__ s_a,
                                          float* __restrict__ v_b, float* __restrict__ s_b,
                                          float* __restrict__ v_merged, float* __restrict__ s_merged,
                                          uint32_t num_heads, uint32_t head_dim, uint32_t total) {
  uint32_t t = threadIdx.x;
  uint32_t tx = t & 31u;
  uint32_t row = blockIdx.x * (BLK / 32) + (t >> 5);
  if (row >= total) return;

  float s_a_val = s_a[row];
  float s_b_val = s_b[row];
  float s_max = max(s_a_val, s_b_val);
  s_a_val = math::ptx_exp2(max(s_a_val - s_max, -math::inf));
  s_b_val = math::ptx_exp2(max(s_b_val - s_max, -math::inf));
  float d_sum = s_a_val + s_b_val;
#if RCP
  float r = __builtin_amdgcn_rcpf(d_sum);
  float a_scale = (d_sum > 0.f) ? s_a_val * r : 0.f;
  float b_scale = (d_sum > 0.f) ? s_b_val * r : 0.f;
#else
  float a_scale = (d_sum > 0.f) ? s_a_val / d_sum : 0.f;
  float b_scale = (d_sum > 0.f) ? s_b_val / d_sum : 0.f;
#endif
  vec_t<float, vec_size> v_a_vec, v_b_vec, v_merged_vec;
  size_t off = (size_t)(row * head_dim) + tx * vec_size;
  v_a_vec.cast_load(v_a + off);
  v_b_vec.cast_load(v_b + off);
#pragma unroll
  for (uint32_t i = 0; i < vec_size; ++i) {
    v_merged_vec[i] = a_scale * v_a_vec[i] + b_scale * v_b_vec[i];
  }
  v_merged_vec.cast_store(v_merged + off);
  if (tx == 0 && s_merged != nullptr) {
    s_merged[row] = math::ptx_log2(d_sum) + s_max;
  }
}
