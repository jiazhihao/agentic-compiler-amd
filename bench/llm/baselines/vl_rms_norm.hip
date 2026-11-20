#include "vllm_common.h"

typedef float scalar_t;

#ifndef BLK
#define BLK 1024
#endif
#ifndef KCH
#define KCH 1
#endif
#define NWV (BLK / 64)

struct __align__(16) f4 { float a, b, c, d; };

extern "C" __global__ void vl_rms_norm(
    scalar_t* __restrict__ out,
    const scalar_t* __restrict__ input,
    const int64_t input_stride_d2,
    const int64_t input_stride_d3,
    const int64_t input_stride_d4,
    const int64_t input_shape_d2,
    const int64_t input_shape_d3,
    const scalar_t* __restrict__ weight,
    const int64_t weight_stride,
    const float epsilon, const int num_tokens, const int hidden_size) {
  __shared__ float s_part[NWV];
  float variance = 0.0f;
  const int tid = threadIdx.x;
  const f4* __restrict__ v_in = reinterpret_cast<const f4*>(input + blockIdx.x * input_stride_d2);
  const f4* __restrict__ v_w = reinterpret_cast<const f4*>(weight + blockIdx.x * weight_stride);
  f4* __restrict__ v_out = reinterpret_cast<f4*>(out + (int64_t)blockIdx.x * hidden_size);
  const int NV = hidden_size / 4;

  f4 xr[KCH];
#pragma unroll
  for (int c = 0; c < KCH; ++c) {
    const int i = tid + c * BLK;
    f4 x = {0.f, 0.f, 0.f, 0.f};
    if (i < NV) {
      x = v_in[i];
      variance += x.a * x.a; variance += x.b * x.b; variance += x.c * x.c; variance += x.d * x.d;
    }
    xr[c] = x;
  }
  // rows longer than KCH chunks: strided loop, re-read later
  for (int i = KCH * BLK + tid; i < NV; i += BLK) {
    f4 x = v_in[i];
    variance += x.a * x.a; variance += x.b * x.b; variance += x.c * x.c; variance += x.d * x.d;
  }

  // one reduction per wave, one LDS slot per wave, one barrier; every thread sums the slots itself
  using WarpReduce = cub::WarpReduce<float, 64>;
  __shared__ typename WarpReduce::TempStorage reduceStore[NWV];
  const float wsum = WarpReduce(reduceStore[tid >> 6]).Sum(variance);
  if ((tid & 63) == 0) s_part[tid >> 6] = wsum;
  __syncthreads();
  float total = 0.0f;
#pragma unroll
  for (int k = 0; k < NWV; ++k) total += s_part[k];
  const float sv = rsqrtf(total / hidden_size + epsilon);

#pragma unroll
  for (int c = 0; c < KCH; ++c) {
    const int i = tid + c * BLK;
    if (i < NV) {
      const f4 x = xr[c];
      const f4 w = v_w[i];
      f4 o;
      o.a = x.a * sv * w.a; o.b = x.b * sv * w.b; o.c = x.c * sv * w.c; o.d = x.d * sv * w.d;
      v_out[i] = o;
    }
  }
  for (int i = KCH * BLK + tid; i < NV; i += BLK) {
    const f4 x = v_in[i];
    const f4 w = v_w[i];
    f4 o;
    o.a = x.a * sv * w.a; o.b = x.b * sv * w.b; o.c = x.c * sv * w.c; o.d = x.d * sv * w.d;
    v_out[i] = o;
  }
}
