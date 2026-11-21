#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>

#define D 128
#define NT 1024
#define NCG 8
#define CG (D / NCG)
#define NG (NT / CG)
#define RW 32
#define NR (NT / RW)
#define KB 16
#define VB 16

template <typename Op>
__device__ inline float reduce2(const float* red, float* red2, Op op) {
  const int tid = threadIdx.x;
  __syncthreads();
  if (tid < NR) {
    float r = red[tid * RW];
#pragma unroll
    for (int i = 1; i < RW; ++i) r = op(r, red[tid * RW + i]);
    red2[tid] = r;
  }
  __syncthreads();
  float r = red2[0];
#pragma unroll
  for (int i = 1; i < NR; ++i) r = op(r, red2[i]);
  return r;
}

extern "C" __global__ void attn_decode(const float* q, const float* k, const float* v, float* o, float* lse,
                                       int kv_len, int num_kv_heads, int group_size, float scale) {
  __shared__ float s_p[NT];
  __shared__ float s_red[NT];
  __shared__ float s_red2[NR];
  __shared__ float s_acc[NT];
  const int h = blockIdx.x;
  const int cg = blockIdx.y;
  const int kv_head = h / group_size;
  const size_t stride = (size_t)num_kv_heads * D;
  const float* qh = q + (size_t)h * D;
  const float* keys = k + (size_t)kv_head * D;
  const float* values = v + (size_t)kv_head * D;
  const int tid = threadIdx.x;
  const int c = cg * CG + (tid & (CG - 1));
  const int g = tid / CG;

  float m = -INFINITY;
  float l = 0.0f;
  float oc = 0.0f;

  for (int base = 0; base < kv_len; base += NT) {
    const int j = base + tid;
    float s = -INFINITY;
    if (j < kv_len) {
      const float4* kj = (const float4*)(keys + (size_t)j * stride);
      const float4* q4 = (const float4*)qh;
      s = 0.0f;
#pragma clang loop unroll(disable)
      for (int i = 0; i < D / 4; i += KB) {
        float4 kk[KB];
#pragma unroll
        for (int u = 0; u < KB; ++u) kk[u] = kj[i + u];
#pragma unroll
        for (int u = 0; u < KB; ++u) {
          const float4 qq = q4[i + u];
          s += qq.x * kk[u].x; s += qq.y * kk[u].y; s += qq.z * kk[u].z; s += qq.w * kk[u].w;
        }
      }
      s *= scale;
    }
    s_red[tid] = s;
    const float m_tile = reduce2(s_red, s_red2, [](float a, float b) { return fmaxf(a, b); });
    const float m_new = fmaxf(m, m_tile);
    const float p = (j < kv_len) ? expf(s - m_new) : 0.0f;
    s_p[tid] = p;
    const float l_tile = reduce2(s_p, s_red2, [](float a, float b) { return a + b; });
    const float rescale = expf(m - m_new);
    l = l * rescale + l_tile;

    const int tile = min(NT, kv_len - base);
    float acc = 0.0f;
    const float* vp = values + ((size_t)base + g) * stride + c;
    const size_t vstep = stride * NG;
    int idx = g;
#pragma clang loop unroll(disable)
    for (; idx + (VB - 1) * NG < tile; idx += VB * NG) {
      float vv[VB];
#pragma unroll
      for (int u = 0; u < VB; ++u) vv[u] = vp[u * vstep];
#pragma unroll
      for (int u = 0; u < VB; ++u) acc += s_p[idx + u * NG] * vv[u];
      vp += VB * vstep;
    }
#pragma clang loop unroll(disable)
    for (; idx < tile; idx += NG) { acc += s_p[idx] * vp[0]; vp += vstep; }
    s_acc[tid] = acc;
    __syncthreads();
    if (tid < CG) {
      float a = s_acc[tid];
#pragma unroll
      for (int i = 1; i < NG; ++i) a += s_acc[tid + i * CG];
      oc = oc * rescale + a;
    }
    m = m_new;
  }

  if (tid < CG) o[(size_t)h * D + cg * CG + tid] = oc / l;
  if (tid == 0 && cg == 0) lse[h] = m + logf(l);
}
