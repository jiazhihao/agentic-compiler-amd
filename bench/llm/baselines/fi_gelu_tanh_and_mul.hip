#include "flashinfer_common.h"

__device__ __forceinline__ float act(float val) {
  const float cdf = 0.5f * (1.0f + tanhf((0.7978845608028654f * (val + 0.044715f * val * val * val))));
  return val * cdf;
}

struct f2 { float a, b; };

extern "C" __global__ __launch_bounds__(64) void fi_gelu_tanh_and_mul(float* __restrict__ out,
                                                                    const float* __restrict__ input,
                                                                    const int d) {
  const int64_t token_idx = blockIdx.y;
  const uint32_t idx = blockIdx.x * 64 + threadIdx.x;
  if (idx >= (uint32_t)(d / 4) * 2) return;
  const float* px = input + token_idx * 2 * d + (int64_t)idx * 2;
  const float* py = px + d;
  float* po = out + token_idx * d + (int64_t)idx * 2;
  f2 x = *(const f2*)px;
  f2 y = *(const f2*)py;
  f2 o;
  o.a = act(x.a) * y.a;
  o.b = act(x.b) * y.b;
  *(f2*)po = o;
}
