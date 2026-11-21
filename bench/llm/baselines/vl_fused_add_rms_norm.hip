#include "vllm_common.h"

typedef float scalar_t;

#ifndef BLK
#define BLK 256
#endif
#ifndef KCH
#define KCH 4
#endif

struct f4 { float a, b, c, d; };

extern "C" __global__ void vl_fused_add_rms_norm(
    scalar_t* __restrict__ input,
    const int64_t input_stride,
    scalar_t* __restrict__ residual,
    const scalar_t* __restrict__ weight,
    const float epsilon, const int num_tokens, const int hidden_size,
    const int64_t residual_stride) {
  __shared__ float s_variance;
  float variance = 0.0f;
  const int tid = threadIdx.x;
  scalar_t* __restrict__ in = input + blockIdx.x * input_stride;
  scalar_t* __restrict__ res = residual + blockIdx.x * residual_stride;
  const int D = hidden_size;

  f4 zr[KCH];
#pragma unroll
  for (int c = 0; c < KCH; ++c) {
    const int base = 4 * (tid + c * BLK);
    f4 z = {0.f, 0.f, 0.f, 0.f};
    if (base + 3 < D) {
      float i0 = in[base], i1 = in[base + 1], i2 = in[base + 2], i3 = in[base + 3];
      float r0 = res[base], r1 = res[base + 1], r2 = res[base + 2], r3 = res[base + 3];
      z.a = i0 + r0; z.b = i1 + r1; z.c = i2 + r2; z.d = i3 + r3;
      res[base] = z.a; res[base + 1] = z.b; res[base + 2] = z.c; res[base + 3] = z.d;
      variance += z.a * z.a; variance += z.b * z.b; variance += z.c * z.c; variance += z.d * z.d;
    } else if (base < D) {
      z.a = in[base] + res[base]; res[base] = z.a; variance += z.a * z.a;
      if (base + 1 < D) { z.b = in[base + 1] + res[base + 1]; res[base + 1] = z.b; variance += z.b * z.b; }
      if (base + 2 < D) { z.c = in[base + 2] + res[base + 2]; res[base + 2] = z.c; variance += z.c * z.c; }
    }
    zr[c] = z;
  }
  // rows longer than KCH chunks: plain strided loop, re-read later
  for (int idx = 4 * KCH * BLK + tid; idx < D; idx += BLK) {
    scalar_t z = in[idx];
    z += res[idx];
    variance += z * z;
    res[idx] = z;
  }

  using BlockReduce = cub::BlockReduce<float, 1024>;
  __shared__ typename BlockReduce::TempStorage reduceStore;
  variance = BlockReduce(reduceStore).Reduce(variance, CubAddOp{}, blockDim.x);

  if (threadIdx.x == 0) {
    s_variance = rsqrtf(variance / hidden_size + epsilon);
  }
  __syncthreads();
  const float sv = s_variance;

#pragma unroll
  for (int c = 0; c < KCH; ++c) {
    const int base = 4 * (tid + c * BLK);
    const f4 z = zr[c];
    if (base + 3 < D) {
      float w0 = weight[base], w1 = weight[base + 1], w2 = weight[base + 2], w3 = weight[base + 3];
      float o0 = z.a * sv * w0, o1 = z.b * sv * w1, o2 = z.c * sv * w2, o3 = z.d * sv * w3;
      in[base] = o0; in[base + 1] = o1; in[base + 2] = o2; in[base + 3] = o3;
    } else if (base < D) {
      in[base] = z.a * sv * weight[base];
      if (base + 1 < D) in[base + 1] = z.b * sv * weight[base + 1];
      if (base + 2 < D) in[base + 2] = z.c * sv * weight[base + 2];
    }
  }
  for (int idx = 4 * KCH * BLK + tid; idx < D; idx += BLK) {
    float x = res[idx];
    in[idx] = x * sv * weight[idx];
  }
}
