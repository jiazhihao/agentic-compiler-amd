#include "flashinfer_common.h"

extern "C" __global__ __launch_bounds__(256) void fi_silu_and_mul(float* __restrict__ out,
                                                                    const float* __restrict__ input,
                                                                    const int d, const uint32_t chunks) {
  const uint32_t n = (uint32_t)d / 4u;
  const uint32_t token = blockIdx.x / chunks;
  const uint32_t chunk = blockIdx.x - token * chunks;
  const uint32_t idx = chunk * 256u + threadIdx.x;
  if (idx >= n) return;
  const float* __restrict__ xin = input + (int64_t)token * 2 * d;
  const float* __restrict__ yin = xin + d;
  float* __restrict__ o = out + (int64_t)token * d;
  float x[4], y[4], r[4];
  __builtin_memcpy(x, xin + (uint64_t)idx * 4, 16);
  __builtin_memcpy(y, yin + (uint64_t)idx * 4, 16);
#pragma unroll
  for (uint32_t i = 0; i < 4; ++i) {
    float e = __builtin_exp2f(x[i] * -1.4426950408889634f);
    r[i] = x[i] * __builtin_amdgcn_rcpf(1.0f + e) * y[i];
  }
  __builtin_memcpy(o + (uint64_t)idx * 4, r, 16);
}
