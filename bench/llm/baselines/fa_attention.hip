#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>

#define D 64
#define NT 256
#define NG (NT / 16)
#define R 4
#define ST 2048
#define FM(a, b, c) __builtin_fmaf(a, b, c)

// two-level reduction over NT threads: 32 threads reduce NT/32 values each, then everyone reduces the 32 partials
template <typename Op>
__device__ inline float reduce2(float* red, float* red2, float mine, Op op) {
  const int tid = threadIdx.x;
  red[tid] = mine;
  __syncthreads();
  if (tid < 32) {
    float r = red[tid * (NT / 32)];
#pragma unroll
    for (int i = 1; i < NT / 32; ++i) r = op(r, red[tid * (NT / 32) + i]);
    red2[tid] = r;
  }
  __syncthreads();
  float r = red2[0];
#pragma unroll
  for (int i = 1; i < 32; ++i) r = op(r, red2[i]);
  __syncthreads();
  return r;
}

extern "C" __global__ void fa_attention(const float* Q, const float* K, const float* V, float* out, float* lse,
                                        int n_q, int n_k, float scale, int causal) {
  __shared__ float s_sc[R * ST];
  __shared__ float s_p[R * NT];
  __shared__ float s_red[NT];
  __shared__ float s_red2[32];
  __shared__ float s_acc[NG * D];
  const int i0 = blockIdx.x * R;
  const int tid = threadIdx.x;
  const int ilast = min(i0 + R - 1, n_q - 1);
  const int n_all = causal ? min(ilast + 1, n_k) : n_k;   // keys visited by the workgroup
  const float4* V4 = (const float4*)V;
  const int g = tid >> 4;
  const int c4 = tid & 15;

  float m[R], ll[R], o0[R], o1[R], o2[R], o3[R];
#pragma unroll
  for (int r = 0; r < R; ++r) { m[r] = -INFINITY; ll[r] = 0.0f; o0[r] = 0.0f; o1[r] = 0.0f; o2[r] = 0.0f; o3[r] = 0.0f; }

  for (int sbase = 0; sbase < n_all; sbase += ST) {
    const int sn = min(ST, n_all - sbase);
#pragma clang loop unroll(disable)
    for (int base = 0; base < sn; base += NT) {
      const int j = base + tid;
      const int jc = min(j, sn - 1);
      const float4* kj = (const float4*)(K + (size_t)(sbase + jc) * D);
      float4 kk[16];
#pragma unroll
      for (int u = 0; u < 16; ++u) kk[u] = kj[u];
#pragma clang loop unroll(disable) vectorize(disable) interleave(disable)
      for (int r = 0; r < R; ++r) {
        const int ir = min(i0 + r, n_q - 1);
        const int nk_r = causal ? min(ir + 1, n_k) : n_k;
        const float4* q4 = (const float4*)(Q + (size_t)ir * D);
        float s = 0.0f;
#pragma unroll
        for (int u = 0; u < 16; ++u) {
          const float4 qq = q4[u];
          s = FM(qq.x, kk[u].x, s); s = FM(qq.y, kk[u].y, s); s = FM(qq.z, kk[u].z, s); s = FM(qq.w, kk[u].w, s);
        }
        s *= scale;
        s = (sbase + j < nk_r) ? s : -INFINITY;
        s_sc[r * ST + j] = s;
      }
    }
    float mloc[R];
#pragma unroll
    for (int r = 0; r < R; ++r) mloc[r] = -INFINITY;
#pragma clang loop unroll(disable)
    for (int base = 0; base < sn; base += NT) {
#pragma unroll
      for (int r = 0; r < R; ++r) mloc[r] = fmaxf(mloc[r], s_sc[r * ST + base + tid]);
    }
    float m_new[R];
#pragma unroll
    for (int r = 0; r < R; ++r) {
      const float m_super = reduce2(s_red, s_red2, mloc[r], [](float a, float b) { return fmaxf(a, b); });
      m_new[r] = fmaxf(m[r], m_super);
      const float rescale = expf(m[r] - m_new[r]);
      ll[r] *= rescale; o0[r] *= rescale; o1[r] *= rescale; o2[r] *= rescale; o3[r] *= rescale;
      m[r] = m_new[r];
    }

    const int last = sbase + sn - 1;
#pragma clang loop unroll(disable)
    for (int base = 0; base < sn; base += NT) {
      const int j = base + tid;
#pragma unroll
      for (int r = 0; r < R; ++r) {
        const float p = __builtin_amdgcn_exp2f((s_sc[r * ST + j] - m_new[r]) * 1.44269504088896341f);
        ll[r] += p;
        s_p[r * NT + tid] = p;
      }
      __syncthreads();
#pragma clang loop unroll(disable) vectorize(disable) interleave(disable)
      for (int h = 0; h < 16; h += 8) {
        float4 vv[8];
#pragma unroll
        for (int u = 0; u < 8; ++u) {
          const int row = min(sbase + base + 16 * g + h + u, last);
          vv[u] = V4[(size_t)row * 16 + c4];
        }
#pragma unroll
        for (int r = 0; r < R; ++r) {
          const float4* pp4 = (const float4*)(s_p + r * NT + 16 * g + h);
          const float4 pa = pp4[0];
          const float4 pb = pp4[1];
          o0[r] = FM(pa.x, vv[0].x, o0[r]); o1[r] = FM(pa.x, vv[0].y, o1[r]); o2[r] = FM(pa.x, vv[0].z, o2[r]); o3[r] = FM(pa.x, vv[0].w, o3[r]);
          o0[r] = FM(pa.y, vv[1].x, o0[r]); o1[r] = FM(pa.y, vv[1].y, o1[r]); o2[r] = FM(pa.y, vv[1].z, o2[r]); o3[r] = FM(pa.y, vv[1].w, o3[r]);
          o0[r] = FM(pa.z, vv[2].x, o0[r]); o1[r] = FM(pa.z, vv[2].y, o1[r]); o2[r] = FM(pa.z, vv[2].z, o2[r]); o3[r] = FM(pa.z, vv[2].w, o3[r]);
          o0[r] = FM(pa.w, vv[3].x, o0[r]); o1[r] = FM(pa.w, vv[3].y, o1[r]); o2[r] = FM(pa.w, vv[3].z, o2[r]); o3[r] = FM(pa.w, vv[3].w, o3[r]);
          o0[r] = FM(pb.x, vv[4].x, o0[r]); o1[r] = FM(pb.x, vv[4].y, o1[r]); o2[r] = FM(pb.x, vv[4].z, o2[r]); o3[r] = FM(pb.x, vv[4].w, o3[r]);
          o0[r] = FM(pb.y, vv[5].x, o0[r]); o1[r] = FM(pb.y, vv[5].y, o1[r]); o2[r] = FM(pb.y, vv[5].z, o2[r]); o3[r] = FM(pb.y, vv[5].w, o3[r]);
          o0[r] = FM(pb.z, vv[6].x, o0[r]); o1[r] = FM(pb.z, vv[6].y, o1[r]); o2[r] = FM(pb.z, vv[6].z, o2[r]); o3[r] = FM(pb.z, vv[6].w, o3[r]);
          o0[r] = FM(pb.w, vv[7].x, o0[r]); o1[r] = FM(pb.w, vv[7].y, o1[r]); o2[r] = FM(pb.w, vv[7].z, o2[r]); o3[r] = FM(pb.w, vv[7].w, o3[r]);
        }
      }
      __syncthreads();
    }
  }

#pragma unroll
  for (int r = 0; r < R; ++r) {
    const int ir = i0 + r;
    const float l = reduce2(s_red, s_red2, ll[r], [](float a, float b) { return a + b; });
    float4 ov; ov.x = o0[r]; ov.y = o1[r]; ov.z = o2[r]; ov.w = o3[r];
    *(float4*)(s_acc + g * D + 4 * c4) = ov;
    __syncthreads();
    if (tid < D) {
      float a = s_acc[tid];
#pragma unroll
      for (int gg = 1; gg < NG; ++gg) a += s_acc[gg * D + tid];
      if (ir < n_q) {
        out[(size_t)ir * D + tid] = a / l;
        if (tid == 0) lse[ir] = m[r] + logf(l);
      }
    }
    __syncthreads();
  }
}
