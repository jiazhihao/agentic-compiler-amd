// From FlashInfer (flashinfer-ai/flashinfer @ 5cd7ab08e2a7, Apache-2.0; see LICENSES.md and README.md).
// activation::act_and_mul_kernel<T = float, Activation = gelu_tanh, vec_size = 4>, include/flashinfer/activation.cuh,
// with gelu_tanh from flashinfer/jit/activation.py (the JIT template that instantiates and launches the kernel:
// vec_size = 16 / sizeof(float) = 4 for d a multiple of 4, blockDim = min(d / vec_size, 256), one block per
// token; the launcher uses this kernel when there are at least 2 blocks per SM / CU, and
// act_and_mul_split_kernel below that).
// Removed: the griddepcontrol (programmatic dependent launch) asm, which is sm_90-only.
#include "flashinfer_common.h"

using namespace flashinfer;

__device__ __forceinline__ float gelu_tanh(const float& val) {
  const float cdf =
      0.5f * (1.0f + math::tanh((0.7978845608028654f * (val + 0.044715f * val * val * val))));
  return val * cdf;
}

template <typename T, float (*Activation)(const float&), uint32_t vec_size>
__device__ __forceinline__ void act_and_mul_kernel(T* __restrict__ out, const T* __restrict__ input, const int d) {
  const int64_t token_idx = blockIdx.x;
  const int64_t thread_idx = threadIdx.x;
  const int64_t stride = blockDim.x;
  const int64_t offset = token_idx * 2 * d;

#pragma unroll 1
  for (uint32_t idx = thread_idx; idx < d / vec_size; idx += stride) {
    vec_t<float, vec_size> x_vec, y_vec, out_vec;
    x_vec.cast_load(input + offset + idx * vec_size);
    y_vec.cast_load(input + offset + d + idx * vec_size);
#pragma unroll
    for (uint32_t i = 0; i < vec_size; ++i) {
      out_vec[i] = Activation(x_vec[i]) * y_vec[i];
    }
    out_vec.cast_store(out + token_idx * d + idx * vec_size);
  }
}

extern "C" __global__ __launch_bounds__(256) void fi_gelu_tanh_and_mul(float* __restrict__ out,
                                                                    const float* __restrict__ input,
                                                                    const int d) {
  act_and_mul_kernel<float, gelu_tanh, 4>(out, input, d);
}
