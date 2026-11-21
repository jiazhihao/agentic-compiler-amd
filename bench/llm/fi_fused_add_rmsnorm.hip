// From FlashInfer (flashinfer-ai/flashinfer @ 5cd7ab08e2a7, Apache-2.0; see LICENSES.md and README.md).
// FusedAddRMSNormKernel<VEC_SIZE = 4, T = float>, include/flashinfer/norm.cuh (the launcher FusedAddRMSNorm
// picks VEC_SIZE = gcd(16 / sizeof(float), d) = 4 for d a multiple of 4, and weight_bias = 0).
// Removed: the griddepcontrol (programmatic dependent launch) asm, which is sm_90-only.
#include "flashinfer_common.h"

using namespace flashinfer;
#define VEC_SIZE 4
typedef float T;

extern "C" __global__ void fi_fused_add_rmsnorm(T* __restrict__ input, T* __restrict__ residual,
                                                T* __restrict__ weight, const uint32_t d,
                                                const uint32_t stride_input, const uint32_t stride_residual,
                                                float weight_bias, float eps) {
  const uint32_t bx = blockIdx.x;
  const uint32_t tx = threadIdx.x, ty = threadIdx.y;
  constexpr uint32_t warp_size = 32;
  const uint32_t num_warps = blockDim.y;
  const uint32_t thread_id = tx + ty * warp_size;
  const uint32_t num_threads = num_warps * warp_size;
  const uint32_t rounds = ceil_div(d, VEC_SIZE * num_threads);
  extern __shared__ float smem[];
  float* smem_x = smem + ceil_div(num_warps, 4) * 4;

  float sum_sq = 0.f;

  for (uint32_t i = 0; i < rounds; i++) {
    vec_t<T, VEC_SIZE> input_vec;
    input_vec.fill(0.f);
    vec_t<T, VEC_SIZE> residual_vec;
    residual_vec.fill(0.f);
    vec_t<float, VEC_SIZE> x_vec;
    x_vec.fill(0.f);
    if ((i * num_threads + thread_id) * VEC_SIZE < d) {
      input_vec.load(input + bx * stride_input + i * num_threads * VEC_SIZE + thread_id * VEC_SIZE);
      residual_vec.load(residual + bx * stride_residual + i * num_threads * VEC_SIZE +
                        thread_id * VEC_SIZE);
    }
#pragma unroll
    for (uint32_t j = 0; j < VEC_SIZE; j++) {
      float x = float(input_vec[j]);
      x += float(residual_vec[j]);
      sum_sq += x * x;
      residual_vec[j] = (T)x;
      x_vec[j] = x;
    }
    if ((i * num_threads + thread_id) * VEC_SIZE < d) {
      residual_vec.store(residual + bx * stride_residual + i * num_threads * VEC_SIZE +
                         thread_id * VEC_SIZE);
      x_vec.store(smem_x + i * num_threads * VEC_SIZE + thread_id * VEC_SIZE);
    }
  }

  // first, warp reduce sum
#pragma unroll
  for (uint32_t offset = warp_size / 2; offset > 0; offset /= 2) {
    sum_sq += math::shfl_xor_sync(sum_sq, offset);
  }

  if (tx == 0) {
    smem[ty] = sum_sq;
  }
  __syncthreads();
  // then, cross warp reduce sum using only the first warp
  if (ty == 0) {
    sum_sq = (tx < num_warps) ? smem[tx] : 0.f;
#pragma unroll
    for (uint32_t offset = warp_size / 2; offset > 0; offset /= 2) {
      sum_sq += math::shfl_xor_sync(sum_sq, offset);
    }
    if (tx == 0) {
      smem[0] = sum_sq;
    }
  }
  __syncthreads();

  float rms_rcp = math::rsqrt(smem[0] / float(d) + eps);

  for (uint32_t i = 0; i < rounds; i++) {
    vec_t<T, VEC_SIZE> input_vec;
    vec_t<T, VEC_SIZE> weight_vec;
    vec_t<float, VEC_SIZE> x_vec;
    input_vec.fill(0.f);
    weight_vec.fill(0.f);
    x_vec.fill(0.f);
    if ((i * num_threads + thread_id) * VEC_SIZE < d) {
      weight_vec.load(weight + i * num_threads * VEC_SIZE + thread_id * VEC_SIZE);
      x_vec.load(smem_x + i * num_threads * VEC_SIZE + thread_id * VEC_SIZE);
    }
#pragma unroll
    for (uint32_t j = 0; j < VEC_SIZE; j++) {
      input_vec[j] = x_vec[j] * rms_rcp * (weight_bias + float(weight_vec[j]));
    }
    if ((i * num_threads + thread_id) * VEC_SIZE < d) {
      input_vec.store(input + bx * stride_input + i * num_threads * VEC_SIZE +
                      thread_id * VEC_SIZE);
    }
  }
}
