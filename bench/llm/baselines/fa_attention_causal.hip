#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>
#define D 64
#define W 4
#define CH 16
#define LOG2E 1.4426950408889634f
extern "C" __global__ void fa_attention(const float* __restrict__ Q, const float* __restrict__ K,
                                        const float* __restrict__ V, float* __restrict__ out,
                                        float* __restrict__ lse, int n_q, int n_k, float scale, int causal) {
  __shared__ float s_all[W][D];
  __shared__ float s_o[W][D];
  __shared__ float s_m[W][D];
  __shared__ float s_l[W][D];
  const int i = blockIdx.x;
  const int tid = threadIdx.x & 63;
  const int w = threadIdx.x >> 6;
  float* s_red = s_all[w];
  const int n_keys = causal ? min(i + 1, n_k) : n_k;
  const float* q = Q + (size_t)i * D;
  float m = -INFINITY, l = 0.0f, o = 0.0f;
  if (w * D < n_keys) {
    float qv[D];
    for (int c = 0; c < D; ++c) qv[c] = q[c];
    for (int base = w * D; base < n_keys; base += W * D) {
      const int j = base + tid;
      const bool live = j < n_keys;
      float s = -INFINITY;
      if (live) {
        const float4* kj = (const float4*)(K + (size_t)j * D);
        float4 kv[D / 4];
        for (int c = 0; c < D / 4; ++c) kv[c] = kj[c];
        s = 0.0f;
        for (int c = 0; c < D / 4; ++c) {
          s += qv[4 * c] * kv[c].x;
          s += qv[4 * c + 1] * kv[c].y;
          s += qv[4 * c + 2] * kv[c].z;
          s += qv[4 * c + 3] * kv[c].w;
        }
        s *= scale;
      }
      s_red[tid] = s;
      float m_new = m;
      {
        float x[D];
        for (int c = 0; c < D; ++c) x[c] = s_red[c];
        for (int h = D / 2; h > 0; h >>= 1)
          for (int c = 0; c < h; ++c) x[c] = fmaxf(x[c], x[c + h]);
        m_new = fmaxf(m, x[0]);
      }
      const float p = live ? __builtin_amdgcn_exp2f((s - m_new) * LOG2E) : 0.0f;
      s_red[tid] = p;
      float lt;
      {
        float x[D];
        for (int c = 0; c < D; ++c) x[c] = s_red[c];
        for (int h = D / 2; h > 0; h >>= 1)
          for (int c = 0; c < h; ++c) x[c] = x[c] + x[c + h];
        lt = x[0];
      }
      const float rescale = __builtin_amdgcn_exp2f((m - m_new) * LOG2E);
      l = l * rescale + lt;
      const int tile = min(D, n_keys - base);
      const float* vb = V + (size_t)base * D + tid;
      float acc = 0.0f;
      int t = 0;
      for (; t + CH <= tile; t += CH) {
        float vv[CH];
        for (int u = 0; u < CH; ++u) vv[u] = vb[(size_t)(t + u) * D];
        for (int u = 0; u < CH; ++u) acc += s_red[t + u] * vv[u];
      }
      for (; t < tile; ++t) acc += s_red[t] * vb[(size_t)t * D];
      o = o * rescale + acc;
      m = m_new;
    }
  }
  s_o[w][tid] = o;
  s_m[w][tid] = m;
  s_l[w][tid] = l;
  __syncthreads();
  if (w == 0) {
    float M = -INFINITY;
    float mw[W];
    for (int u = 0; u < W; ++u) { mw[u] = s_m[u][tid]; M = fmaxf(M, mw[u]); }
    float L = 0.0f, O = 0.0f;
    for (int u = 0; u < W; ++u) {
      const float f = __builtin_amdgcn_exp2f((mw[u] - M) * LOG2E);
      L += f * s_l[u][tid];
      O += f * s_o[u][tid];
    }
    out[(size_t)i * D + tid] = O / L;
    if (tid == 0) lse[i] = M + logf(L);
  }
}
