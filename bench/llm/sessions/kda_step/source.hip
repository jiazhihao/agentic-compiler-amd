#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>

#define KDA_MAX_DK 256
#ifndef CW
#define CW 4
#endif
#ifndef UR
#define UR 4
#endif
#ifndef PR
#define PR 8
#endif
#ifndef LPOOL
#define LPOOL 19200
#endif

extern "C" __global__ void kda_step(float* S, const float* g, const float* k, const float* v, const float* beta,
                                    const float* q, float* o, int dk, int dv, float scale) {
  __shared__ float s_decay[KDA_MAX_DK];   // exp(g)
  __shared__ float s_k[KDA_MAX_DK];
  __shared__ float s_q[KDA_MAX_DK];       // scale * q
  __shared__ float s_pool[LPOOL];         // decayed S of this head, then partial sums
  const int h = blockIdx.x;
  const int tid = threadIdx.x;
  const int bd = blockDim.x;
  for (int i = tid; i < dk; i += bd) {
    s_decay[i] = expf(g[(size_t)h * dk + i]);
    s_k[i] = k[(size_t)h * dk + i];
    s_q[i] = scale * q[(size_t)h * dk + i];
  }
  __syncthreads();

  float* Sh = S + (size_t)h * dk * dv;
  const float b = beta[h];
  const bool fast = dv >= CW && ((long)dk * dv + 2L * PR * dv) <= (long)LPOOL;
  if (fast) {
    const int ncg = (dv + CW - 1) / CW;
    const int nitem = ncg * PR;
    float* s_pp = s_pool + dk * dv;
    float* s_po = s_pp + PR * dv;
    // phase 1: read S once, decay, park in LDS, partial pred per row part
    for (int w = tid; w < nitem; w += bd) {
      const int p = w / ncg, cg = w - p * ncg;
      int c = cg * CW; if (c > dv - CW) c = dv - CW;
      const int r0 = (p * dk) / PR, r1 = ((p + 1) * dk) / PR;
      float pred[CW];
      for (int j = 0; j < CW; ++j) pred[j] = 0.0f;
      int i = r0;
      for (; i + UR <= r1; i += UR) {
        float t[UR][CW];
        for (int r = 0; r < UR; ++r) __builtin_memcpy(t[r], Sh + (size_t)(i + r) * dv + c, sizeof(float) * CW);
        for (int r = 0; r < UR; ++r) {
          const float kk = s_k[i + r], dd = s_decay[i + r];
          for (int j = 0; j < CW; ++j) { t[r][j] *= dd; pred[j] += kk * t[r][j]; }
          __builtin_memcpy(s_pool + (i + r) * dv + c, t[r], sizeof(float) * CW);
        }
      }
      for (; i < r1; ++i) {
        float t[CW];
        __builtin_memcpy(t, Sh + (size_t)i * dv + c, sizeof(float) * CW);
        const float kk = s_k[i], dd = s_decay[i];
        for (int j = 0; j < CW; ++j) { t[j] *= dd; pred[j] += kk * t[j]; }
        __builtin_memcpy(s_pool + i * dv + c, t, sizeof(float) * CW);
      }
      __builtin_memcpy(s_pp + p * dv + c, pred, sizeof(float) * CW);
    }
    __syncthreads();
    // phase 2: delta rule from LDS, write S once, partial out
    for (int w = tid; w < nitem; w += bd) {
      const int p = w / ncg, cg = w - p * ncg;
      int c = cg * CW; if (c > dv - CW) c = dv - CW;
      const int r0 = (p * dk) / PR, r1 = ((p + 1) * dk) / PR;
      float u[CW], out[CW], pred[CW];
      for (int j = 0; j < CW; ++j) { pred[j] = 0.0f; out[j] = 0.0f; }
      for (int pp = 0; pp < PR; ++pp) {
        float t[CW];
        __builtin_memcpy(t, s_pp + pp * dv + c, sizeof(float) * CW);
        for (int j = 0; j < CW; ++j) pred[j] += t[j];
      }
      __builtin_memcpy(u, v + (size_t)h * dv + c, sizeof(float) * CW);
      for (int j = 0; j < CW; ++j) u[j] -= pred[j];
      for (int i = r0; i < r1; ++i) {
        float t[CW];
        __builtin_memcpy(t, s_pool + i * dv + c, sizeof(float) * CW);
        const float kk = b * s_k[i], qq = s_q[i];
        for (int j = 0; j < CW; ++j) { t[j] += kk * u[j]; out[j] += qq * t[j]; }
        __builtin_memcpy(Sh + (size_t)i * dv + c, t, sizeof(float) * CW);
      }
      __builtin_memcpy(s_po + p * dv + c, out, sizeof(float) * CW);
    }
    __syncthreads();
    for (int cg = tid; cg < ncg; cg += bd) {
      int c = cg * CW; if (c > dv - CW) c = dv - CW;
      float out[CW];
      for (int j = 0; j < CW; ++j) out[j] = 0.0f;
      for (int pp = 0; pp < PR; ++pp) {
        float t[CW];
        __builtin_memcpy(t, s_po + pp * dv + c, sizeof(float) * CW);
        for (int j = 0; j < CW; ++j) out[j] += t[j];
      }
      __builtin_memcpy(o + (size_t)h * dv + c, out, sizeof(float) * CW);
    }
  } else {
    for (int c = tid; c < dv; c += bd) {
      float pred = 0.0f;
      for (int i = 0; i < dk; ++i) pred += s_k[i] * (Sh[(size_t)i * dv + c] * s_decay[i]);
      const float u = v[(size_t)h * dv + c] - pred;
      float out = 0.0f;
      for (int i = 0; i < dk; ++i) {
        const float s_new = Sh[(size_t)i * dv + c] * s_decay[i] + (b * s_k[i]) * u;
        Sh[(size_t)i * dv + c] = s_new;
        out += s_q[i] * s_new;
      }
      o[(size_t)h * dv + c] = out;
    }
  }
}
