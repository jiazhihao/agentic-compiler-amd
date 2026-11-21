#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>

#define DQ 576
#define DV 512
#define NT 1024
#define HB 2
#define NCG 1
#define NQ (DV / 4 / NCG)
#define NG (NT / NQ)
#define RW 32
#define NR (NT / RW)
#define KB 4
#define VB 8

extern "C" __global__ void mla_decode(const float* q, const float* kv_cache,
                                      float* out, float* lse,
                                      int num_heads, int kv_len, float scale) {
  __shared__ float s_p[NT * HB];
  __shared__ float s_red2[HB * NR];
  __shared__ float s_mt[HB];
  __shared__ float s_resc[HB];
  __shared__ float s_l[HB];
  __shared__ float4 s_acc[NT];
  __shared__ float4 s_o[HB * NQ];
  const int tid = threadIdx.x;
  const int h0 = blockIdx.x * HB, b = blockIdx.y, cg = blockIdx.z;
  const float* kv = kv_cache + (size_t)b * kv_len * DQ;
  const size_t row0 = (size_t)b * num_heads;
  const int cq = tid & (NQ - 1);
  const int g = tid / NQ;
  const int c = (cg * NQ + cq) * 4;
  const float4* qrow[HB];
#pragma unroll
  for (int h = 0; h < HB; ++h) qrow[h] = (const float4*)(q + (row0 + min(h0 + h, num_heads - 1)) * DQ);

  float m = -INFINITY;
  float l = 0.0f;
  if (tid < NQ) {
#pragma unroll
    for (int h = 0; h < HB; ++h) s_o[h * NQ + tid] = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
  }

  for (int base = 0; base < kv_len; base += NT) {
    const int j = base + tid;
    float s[HB];
#pragma unroll
    for (int h = 0; h < HB; ++h) s[h] = -INFINITY;
    if (j < kv_len) {
      const float4* kj = (const float4*)(kv + (size_t)j * DQ);
#pragma unroll
      for (int h = 0; h < HB; ++h) s[h] = 0.0f;
#pragma clang loop unroll(disable)
      for (int i = 0; i < DQ / 4; i += KB) {
        float4 kk[KB];
#pragma unroll
        for (int u = 0; u < KB; ++u) kk[u] = kj[i + u];
#pragma unroll
        for (int h = 0; h < HB; ++h) {
          const float4* q4 = qrow[h];
          float sh = s[h];
#pragma unroll
          for (int u = 0; u < KB; ++u) {
            const float4 qq = q4[i + u];
            sh += qq.x * kk[u].x; sh += qq.y * kk[u].y; sh += qq.z * kk[u].z; sh += qq.w * kk[u].w;
          }
          s[h] = sh;
        }
      }
#pragma unroll
      for (int h = 0; h < HB; ++h) s[h] *= scale;
    }
#pragma unroll
    for (int h = 0; h < HB; ++h) s_p[tid * HB + h] = s[h];
    __syncthreads();
    if (tid < HB * NR) {
      const int hh = tid / NR, r0 = tid % NR;
      float r = s_p[(r0 * RW) * HB + hh];
#pragma unroll
      for (int i = 1; i < RW; ++i) r = fmaxf(r, s_p[(r0 * RW + i) * HB + hh]);
      s_red2[tid] = r;
    }
    __syncthreads();
    if (tid < HB) {
      float r = s_red2[tid * NR];
#pragma unroll
      for (int i = 1; i < NR; ++i) r = fmaxf(r, s_red2[tid * NR + i]);
      const float m_new = fmaxf(m, r);
      s_mt[tid] = m_new;
      s_resc[tid] = expf(m - m_new);
      m = m_new;
    }
    __syncthreads();
#pragma unroll
    for (int h = 0; h < HB; ++h) {
      const float p = (j < kv_len) ? expf(s[h] - s_mt[h]) : 0.0f;
      s_p[tid * HB + h] = p;
    }
    __syncthreads();
    if (tid < HB * NR) {
      const int hh = tid / NR, r0 = tid % NR;
      float r = s_p[(r0 * RW) * HB + hh];
#pragma unroll
      for (int i = 1; i < RW; ++i) r += s_p[(r0 * RW + i) * HB + hh];
      s_red2[tid] = r;
    }
    __syncthreads();
    if (tid < HB) {
      float r = s_red2[tid * NR];
#pragma unroll
      for (int i = 1; i < NR; ++i) r += s_red2[tid * NR + i];
      l = l * s_resc[tid] + r;
      s_l[tid] = l;
    }

    const int tile = min(NT, kv_len - base);
    float4 acc[HB];
#pragma unroll
    for (int h = 0; h < HB; ++h) acc[h] = make_float4(0.0f, 0.0f, 0.0f, 0.0f);
    const float* vp = kv + ((size_t)base + g) * DQ + c;
    int idx = g;
#pragma clang loop unroll(disable)
    for (; idx + (VB - 1) * NG < tile; idx += VB * NG) {
      float4 vv[VB];
#pragma unroll
      for (int u = 0; u < VB; ++u) vv[u] = *(const float4*)(vp + (size_t)u * NG * DQ);
#pragma unroll
      for (int u = 0; u < VB; ++u) {
        const float* pp = &s_p[(idx + u * NG) * HB];
#pragma unroll
        for (int h = 0; h < HB; ++h) {
          const float ph = pp[h];
          acc[h].x += ph * vv[u].x; acc[h].y += ph * vv[u].y; acc[h].z += ph * vv[u].z; acc[h].w += ph * vv[u].w;
        }
      }
      vp += (size_t)VB * NG * DQ;
    }
#pragma clang loop unroll(disable)
    for (; idx < tile; idx += NG) {
      const float4 v1 = *(const float4*)vp;
      const float* pp = &s_p[idx * HB];
#pragma unroll
      for (int h = 0; h < HB; ++h) {
        const float ph = pp[h];
        acc[h].x += ph * v1.x; acc[h].y += ph * v1.y; acc[h].z += ph * v1.z; acc[h].w += ph * v1.w;
      }
      vp += (size_t)NG * DQ;
    }
#pragma unroll
    for (int h = 0; h < HB; ++h) {
      s_acc[tid] = acc[h];
      __syncthreads();
      if (tid < NQ) {
        float4 a = s_acc[tid];
#pragma unroll
        for (int i = 1; i < NG; ++i) {
          const float4 t = s_acc[tid + i * NQ];
          a.x += t.x; a.y += t.y; a.z += t.z; a.w += t.w;
        }
        const float rs = s_resc[h];
        const float4 o = s_o[h * NQ + tid];
        a.x = o.x * rs + a.x; a.y = o.y * rs + a.y; a.z = o.z * rs + a.z; a.w = o.w * rs + a.w;
        s_o[h * NQ + tid] = a;
      }
      __syncthreads();
    }
  }

  if (tid < NQ) {
#pragma unroll
    for (int h = 0; h < HB; ++h) {
      if (h0 + h < num_heads) {
        float4* op = (float4*)(out + (row0 + h0 + h) * DV + c);
        const float lh = s_l[h];
        float4 o = s_o[h * NQ + tid];
        o.x /= lh; o.y /= lh; o.z /= lh; o.w /= lh;
        *op = o;
      }
    }
  }
  if (tid < HB && cg == 0 && h0 + tid < num_heads) lse[row0 + h0 + tid] = m + logf(l);
}
