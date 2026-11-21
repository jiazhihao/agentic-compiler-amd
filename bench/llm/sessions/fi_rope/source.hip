#include "flashinfer_common.h"
#include <math.h>
using namespace flashinfer;
#ifndef HG
#define HG 8
#endif
typedef float DType;
typedef int32_t IdType;

// freq of the 4 elements of vector t (4 t .. 4 t + 3), exactly as the baseline computes it
static __device__ __forceinline__ void rope_sincos(uint32_t t, uint32_t rotary_dim, float pos,
    float smooth_a, float smooth_b, float rope_rcp_scale, float rope_rcp_theta, float4& c, float4& s) {
  float* cp = (float*)&c; float* sp = (float*)&s;
#pragma unroll
  for (uint32_t i = 0; i < 4; ++i) {
    float f = powf(rope_rcp_theta, float(2 * ((t * 4 + i) % (rotary_dim / 2))) / float(rotary_dim));
    float smooth = f * smooth_a + smooth_b;
    smooth = max(0.0f, min(1.0f, smooth));
    f = (1 - smooth) * (f * rope_rcp_scale) + smooth * f;
    float embed = pos * f;
    sincosf(embed, &sp[i], &cp[i]);
  }
}

extern "C" __global__ void fi_rope(
    DType* q, DType* k, DType* q_rope, DType* k_rope, IdType* __restrict__ pos_ids, uint32_t nnz,
    uint32_t num_qo_heads, uint32_t num_kv_heads, uint32_t rotary_dim, size_t q_stride_n,
    size_t q_stride_h, size_t k_stride_n, size_t k_stride_h, size_t q_rope_stride_n,
    size_t q_rope_stride_h, size_t k_rope_stride_n, size_t k_rope_stride_h, float smooth_a,
    float smooth_b, float rope_rcp_scale, float rope_rcp_theta) {
  const uint32_t tx = threadIdx.x;              // 0..15: vectors tx and tx + 16
  const uint32_t idx = blockIdx.x * blockDim.y + threadIdx.y;
  if (idx >= nnz) return;
  const uint32_t total = num_qo_heads + num_kv_heads;
  const uint32_t h0 = blockIdx.y * HG;
  if (h0 >= total) return;
  const uint32_t nh = min((uint32_t)HG, total - h0);
  const float pos = float(pos_ids[idx]);
  const uint32_t lo = tx * 4, hi = tx * 4 + 64;

  if (rotary_dim == 128) {
    // elements e and e + 64 share the angle: one sincos per pair, each input read once
    float4 c, s;
    rope_sincos(tx, rotary_dim, pos, smooth_a, smooth_b, rope_rcp_scale, rope_rcp_theta, c, s);
    if (nh == HG) {
      const float* src[HG]; float* dst[HG];
      float4 a[HG], b[HG];
#pragma unroll
      for (uint32_t j = 0; j < HG; ++j) {
        const uint32_t h = h0 + j;
        const bool isq = h < num_qo_heads;
        const uint32_t hh = isq ? h : h - num_qo_heads;
        src[j] = (isq ? q : k) + (size_t)idx * (isq ? q_stride_n : k_stride_n) + (size_t)hh * (isq ? q_stride_h : k_stride_h);
        dst[j] = (isq ? q_rope : k_rope) + (size_t)idx * (isq ? q_rope_stride_n : k_rope_stride_n) + (size_t)hh * (isq ? q_rope_stride_h : k_rope_stride_h);
        a[j] = *(const float4*)(src[j] + lo);
        b[j] = *(const float4*)(src[j] + hi);
      }
#pragma unroll
      for (uint32_t j = 0; j < HG; ++j) {
        float4 o1, o2;
        o1.x = a[j].x * c.x + (-b[j].x) * s.x; o1.y = a[j].y * c.y + (-b[j].y) * s.y;
        o1.z = a[j].z * c.z + (-b[j].z) * s.z; o1.w = a[j].w * c.w + (-b[j].w) * s.w;
        o2.x = b[j].x * c.x + a[j].x * s.x; o2.y = b[j].y * c.y + a[j].y * s.y;
        o2.z = b[j].z * c.z + a[j].z * s.z; o2.w = b[j].w * c.w + a[j].w * s.w;
        *(float4*)(dst[j] + lo) = o1;
        *(float4*)(dst[j] + hi) = o2;
      }
    } else {
      for (uint32_t j = 0; j < nh; ++j) {
        const uint32_t h = h0 + j;
        const bool isq = h < num_qo_heads;
        const uint32_t hh = isq ? h : h - num_qo_heads;
        const float* sp = (isq ? q : k) + (size_t)idx * (isq ? q_stride_n : k_stride_n) + (size_t)hh * (isq ? q_stride_h : k_stride_h);
        float* dp = (isq ? q_rope : k_rope) + (size_t)idx * (isq ? q_rope_stride_n : k_rope_stride_n) + (size_t)hh * (isq ? q_rope_stride_h : k_rope_stride_h);
        float4 a = *(const float4*)(sp + lo), b = *(const float4*)(sp + hi);
        float4 o1, o2;
        o1.x = a.x * c.x + (-b.x) * s.x; o1.y = a.y * c.y + (-b.y) * s.y;
        o1.z = a.z * c.z + (-b.z) * s.z; o1.w = a.w * c.w + (-b.w) * s.w;
        o2.x = b.x * c.x + a.x * s.x; o2.y = b.y * c.y + a.y * s.y;
        o2.z = b.z * c.z + a.z * s.z; o2.w = b.w * c.w + a.w * s.w;
        *(float4*)(dp + lo) = o1;
        *(float4*)(dp + hi) = o2;
      }
    }
  } else {
    // general rotary_dim: the baseline's per-vector rule, for vectors tx and tx + 16
    for (uint32_t v = 0; v < 2; ++v) {
      const uint32_t t = tx + 16 * v;
      const bool rot = t * 4 < rotary_dim;
      const bool first = t * 4 < rotary_dim / 2;
      float4 c = make_float4(0, 0, 0, 0), s = c;
      if (rot) rope_sincos(t, rotary_dim, pos, smooth_a, smooth_b, rope_rcp_scale, rope_rcp_theta, c, s);
      for (uint32_t j = 0; j < nh; ++j) {
        const uint32_t h = h0 + j;
        const bool isq = h < num_qo_heads;
        const uint32_t hh = isq ? h : h - num_qo_heads;
        const float* sp = (isq ? q : k) + (size_t)idx * (isq ? q_stride_n : k_stride_n) + (size_t)hh * (isq ? q_stride_h : k_stride_h);
        float* dp = (isq ? q_rope : k_rope) + (size_t)idx * (isq ? q_rope_stride_n : k_rope_stride_n) + (size_t)hh * (isq ? q_rope_stride_h : k_rope_stride_h);
        float4 x = *(const float4*)(sp + t * 4);
        if (rot) {
          float4 p = *(const float4*)(sp + (first ? t * 4 + rotary_dim / 2 : t * 4 - rotary_dim / 2));
          const float sg = first ? -1.0f : 1.0f;
          x.x = x.x * c.x + (sg * p.x) * s.x; x.y = x.y * c.y + (sg * p.y) * s.y;
          x.z = x.z * c.z + (sg * p.z) * s.z; x.w = x.w * c.w + (sg * p.w) * s.w;
        }
        *(float4*)(dp + t * 4) = x;
      }
    }
  }
}
