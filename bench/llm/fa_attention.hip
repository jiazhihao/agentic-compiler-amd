// PORT: written for this benchmark, not extracted from a library (see README.md "Ports").
// FlashAttention-style attention forward for one head: out[i] = softmax_j(scale * Q[i] . K[j]) V[j], computed
// tile by tile over K / V with the online-softmax recurrence (attn_port.h). Reference: the FlashAttention
// paper (Dao et al., 2022, Algorithm 1) and Dao-AILab/flash-attention. d = 64; one block of 64 threads per
// query row. causal != 0: query i attends to keys 0..i (Q and K have the same length).
#include "attn_port.h"

#define D 64

extern "C" __global__ void fa_attention(const float* Q, const float* K, const float* V, float* out, float* lse,
                                        int n_q, int n_k, float scale, int causal) {
  const int i = blockIdx.x;
  const int n_keys = causal ? min(i + 1, n_k) : n_k;
  online_softmax_row<D, D, D>(Q + (size_t)i * D, K, D, V, D, n_keys, scale, out + (size_t)i * D, lse + i);
}
