// PORT: written for this benchmark, not extracted from a library (see README.md "Ports").
// Kimi Delta Attention, one recurrent time step for a batch of heads, exactly the loop body of
// naive_recurrent_kda in fla-org/flash-linear-attention, fla/ops/kda/naive.py (MIT):
//     S = S * exp(g)[:, None]                      S: [dk, dv] per head, g: per-key log-space decay
//     S = S + (beta * k)[:, None] * (v - k^T S)    the delta rule
//     o = (scale * q)^T S
// One block per head; thread c owns column c of S (and further columns in steps of blockDim.x).
// dk <= KDA_MAX_DK.
#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>

#define KDA_MAX_DK 256

extern "C" __global__ void kda_step(float* S, const float* g, const float* k, const float* v, const float* beta,
                                    const float* q, float* o, int dk, int dv, float scale) {
  __shared__ float s_decay[KDA_MAX_DK];   // exp(g)
  __shared__ float s_k[KDA_MAX_DK];
  __shared__ float s_q[KDA_MAX_DK];       // scale * q
  const int h = blockIdx.x;
  for (int i = threadIdx.x; i < dk; i += blockDim.x) {
    s_decay[i] = expf(g[(size_t)h * dk + i]);
    s_k[i] = k[(size_t)h * dk + i];
    s_q[i] = scale * q[(size_t)h * dk + i];
  }
  __syncthreads();

  float* Sh = S + (size_t)h * dk * dv;
  const float b = beta[h];
  for (int c = threadIdx.x; c < dv; c += blockDim.x) {
    float pred = 0.0f;                    // k^T (S * decay), column c
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
