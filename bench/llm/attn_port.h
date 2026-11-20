// PORT (written for this benchmark, not library code; see README.md "Ports").
// One row of attention with the online-softmax recurrence of FlashAttention (Dao et al., 2022, Algorithm 1;
// Dao-AILab/flash-attention): the keys are visited in tiles, a running maximum m and a running sum l of
// exp(score - m) are kept, and the partial output is rescaled by exp(m_old - m_new) at every tile.
// One thread block computes one output row: thread t of a tile scores key base + t (a DQ-long dot product),
// then owns DV / NT output columns and accumulates them over the tile's keys.
#pragma once
#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>

template <int NT, typename Op>
__device__ inline float block_reduce(float* red, float mine, Op op) {
  red[threadIdx.x] = mine;
  __syncthreads();
  for (int s = NT / 2; s > 0; s >>= 1) {
    if (threadIdx.x < s) red[threadIdx.x] = op(red[threadIdx.x], red[threadIdx.x + s]);
    __syncthreads();
  }
  float r = red[0];
  __syncthreads();
  return r;
}

// q: [DQ]; keys: n_keys rows of k_stride floats (the first DQ are scored); values: n_keys rows of v_stride
// floats (the first DV are averaged); out: [DV]; *lse = log(sum_j exp(scale * q . k_j)).
// Launch with blockDim.x == NT (a power of two); DV must be a multiple of NT.
template <int DQ, int DV, int NT>
__device__ inline void online_softmax_row(const float* q, const float* keys, size_t k_stride,
                                          const float* values, size_t v_stride, int n_keys, float scale,
                                          float* out, float* lse) {
  static_assert(DV % NT == 0, "every thread owns DV / NT output columns");
  __shared__ float s_p[NT];     // exp(score - m) of the tile's keys
  __shared__ float s_red[NT];   // reduction scratch
  const int tid = threadIdx.x;

  float m = -INFINITY;          // running maximum of the scores
  float l = 0.0f;               // running sum of exp(score - m)
  float o[DV / NT];             // running sum of exp(score - m) * value, for this thread's columns
  for (int r = 0; r < DV / NT; ++r) o[r] = 0.0f;

  for (int base = 0; base < n_keys; base += NT) {
    const int j = base + tid;
    float s = -INFINITY;
    if (j < n_keys) {
      const float* kj = keys + (size_t)j * k_stride;
      s = 0.0f;
      for (int i = 0; i < DQ; ++i) s += q[i] * kj[i];
      s *= scale;
    }
    const float m_tile = block_reduce<NT>(s_red, s, [](float a, float b) { return fmaxf(a, b); });
    const float m_new = fmaxf(m, m_tile);
    const float p = (j < n_keys) ? expf(s - m_new) : 0.0f;
    s_p[tid] = p;
    const float l_tile = block_reduce<NT>(s_red, p, [](float a, float b) { return a + b; });
    const float rescale = expf(m - m_new);        // 0 for the first tile (m = -inf)
    l = l * rescale + l_tile;

    const int tile = min(NT, n_keys - base);
    for (int r = 0; r < DV / NT; ++r) {
      const int c = tid + r * NT;
      float acc = 0.0f;
      for (int t = 0; t < tile; ++t) acc += s_p[t] * values[(size_t)(base + t) * v_stride + c];
      o[r] = o[r] * rescale + acc;
    }
    m = m_new;
    __syncthreads();                              // s_p is rewritten by the next tile
  }

  for (int r = 0; r < DV / NT; ++r) out[tid + r * NT] = o[r] / l;
  if (tid == 0) *lse = m + logf(l);
}
