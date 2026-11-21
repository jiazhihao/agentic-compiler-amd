#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>

#define KDA_MAX_DK 256
#ifndef CW
#define CW 4
#endif
#ifndef PR
#define PR 8
#endif
#ifndef RMX
#define RMX 16
#endif
#ifndef LPOOL
#define LPOOL 2048
#endif

extern "C" __global__ void kda_step(float* S, const float* g, const float* k, const float* v, const float* beta,
                                    const float* q, float* o, int dk, int dv, float scale) {
  __shared__ float s_decay[KDA_MAX_DK];   // exp(g)
  __shared__ float s_k[KDA_MAX_DK];
  __shared__ float s_q[KDA_MAX_DK];       // scale * q
  __shared__ float s_pool[LPOOL];         // partial sums
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
  const int ncg = (dv + CW - 1) / CW;
  const int nitem = ncg * PR;
  const bool fast = dv >= CW && dk >= PR && dk <= RMX * PR && nitem <= bd && (2L * PR * dv) <= (long)LPOOL;
  if (fast) {
    float* s_pp = s_pool;
    float* s_po = s_pp + PR * dv;
    const bool act = tid < nitem;
    const int p = tid / ncg, cg = tid - p * ncg;
    int c = cg * CW; if (c > dv - CW) c = dv - CW;
    const int r0 = (p * dk) / PR, r1 = ((p + 1) * dk) / PR;
    float t[RMX][CW];
    // phase 1: read S once, decay, keep in registers, partial pred per row part
    if (act) {
      float pred[CW];
      for (int j = 0; j < CW; ++j) pred[j] = 0.0f;
      for (int r = 0; r < RMX; ++r) {
        int row = r0 + r; if (row > r1 - 1) row = r1 - 1;
        __builtin_memcpy(t[r], Sh + (size_t)row * dv + c, sizeof(float) * CW);
      }
      for (int r = 0; r < RMX; ++r) {
        int row = r0 + r; const bool valid = row < r1; if (!valid) row = r1 - 1;
        const float kk = s_k[row], dd = s_decay[row];
        for (int j = 0; j < CW; ++j) { t[r][j] *= dd; pred[j] += valid ? kk * t[r][j] : 0.0f; }
      }
      __builtin_memcpy(s_pp + p * dv + c, pred, sizeof(float) * CW);
    }
    __syncthreads();
    // phase 2: delta rule from registers, write S once, partial out
    if (act) {
      float u[CW], out[CW], pred[CW];
      for (int j = 0; j < CW; ++j) { pred[j] = 0.0f; out[j] = 0.0f; }
      for (int pp = 0; pp < PR; ++pp) {
        float x[CW];
        __builtin_memcpy(x, s_pp + pp * dv + c, sizeof(float) * CW);
        for (int j = 0; j < CW; ++j) pred[j] += x[j];
      }
      __builtin_memcpy(u, v + (size_t)h * dv + c, sizeof(float) * CW);
      for (int j = 0; j < CW; ++j) u[j] -= pred[j];
      for (int r = 0; r < RMX; ++r) {
        int row = r0 + r; const bool valid = row < r1; if (!valid) row = r1 - 1;
        const float kk = b * s_k[row], qq = s_q[row];
        for (int j = 0; j < CW; ++j) { t[r][j] += kk * u[j]; out[j] += valid ? qq * t[r][j] : 0.0f; }
        __builtin_memcpy(Sh + (size_t)row * dv + c, t[r], sizeof(float) * CW);
      }
      __builtin_memcpy(s_po + p * dv + c, out, sizeof(float) * CW);
    }
    __syncthreads();
    if (tid < ncg) {
      int c2 = tid * CW; if (c2 > dv - CW) c2 = dv - CW;
      float out[CW];
      for (int j = 0; j < CW; ++j) out[j] = 0.0f;
      for (int pp = 0; pp < PR; ++pp) {
        float x[CW];
        __builtin_memcpy(x, s_po + pp * dv + c2, sizeof(float) * CW);
        for (int j = 0; j < CW; ++j) out[j] += x[j];
      }
      __builtin_memcpy(o + (size_t)h * dv + c2, out, sizeof(float) * CW);
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
