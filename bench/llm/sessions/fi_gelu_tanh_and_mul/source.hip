#include "flashinfer_common.h"

#ifndef FAST
#define FAST 1
#endif

__device__ __forceinline__ float act(float val) {
#if FAST
  // 0.5*(1+tanh(z)) == 1/(1+exp(-2z)); exp2 argument = -2*z*log2(e)
  const float z = 0.7978845608028654f * (val + 0.044715f * val * val * val);
  const float e = __builtin_amdgcn_exp2f(z * -2.8853900817779268f);
  return val * __builtin_amdgcn_rcpf(1.0f + e);
#else
  const float cdf = 0.5f * (1.0f + tanhf((0.7978845608028654f * (val + 0.044715f * val * val * val))));
  return val * cdf;
#endif
}

struct f4 { float a, b, c, d; };

extern "C" __global__ __launch_bounds__(BLK) void fi_gelu_tanh_and_mul(float* __restrict__ out,
                                                                    const float* __restrict__ input,
                                                                    const int d) {
  const int64_t token_idx = blockIdx.y;
  const uint32_t idx = blockIdx.x * BLK + threadIdx.x;
  if (idx >= (uint32_t)(d / 4)) return;
  const float* px = input + token_idx * 2 * d + (int64_t)idx * 4;
  const float* py = px + d;
  float* po = out + token_idx * d + (int64_t)idx * 4;
  f4 x = *(const f4*)px;
  f4 y = *(const f4*)py;
  f4 o;
  o.a = act(x.a) * y.a;
  o.b = act(x.b) * y.b;
  o.c = act(x.c) * y.c;
  o.d = act(x.d) * y.d;
  *(f4*)po = o;
}
