// PORT: written for this benchmark, not extracted from a library (see README.md "Ports").
// MoE gating: softmax over the expert logits of every token, then the top-k experts by probability with
// their weights, in descending order (ties: the lower expert index first). Semantics of vLLM's topk_softmax
// (csrc/moe/topk_softmax_kernels.cu, topkGating with ScoringFunc softmax, no renormalization, no bias),
// whose kernel is a 300-line template over values-per-thread / bytes-per-load / warp layouts and was not
// extracted. One thread per token.
#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>

#define MAX_K 16

extern "C" __global__ void moe_gate_topk(const float* logits, float* weights, int32_t* indices, int num_tokens,
                                         int num_experts, int k) {
  const int t = blockIdx.x * blockDim.x + threadIdx.x;
  if (t >= num_tokens) return;
  const float* x = logits + (size_t)t * num_experts;

  float m = -INFINITY;
  for (int e = 0; e < num_experts; ++e) m = fmaxf(m, x[e]);
  float sum = 0.0f;
  for (int e = 0; e < num_experts; ++e) sum += expf(x[e] - m);

  int picked[MAX_K];
  for (int r = 0; r < k; ++r) {
    int best = -1;
    float best_x = -INFINITY;
    for (int e = 0; e < num_experts; ++e) {
      bool taken = false;
      for (int p = 0; p < r; ++p) taken |= (picked[p] == e);
      if (!taken && (best < 0 || x[e] > best_x)) {
        best = e;
        best_x = x[e];
      }
    }
    picked[r] = best;
    weights[(size_t)t * k + r] = expf(best_x - m) / sum;
    indices[(size_t)t * k + r] = best;
  }
}
