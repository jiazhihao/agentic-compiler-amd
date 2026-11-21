// PORT: written for this benchmark, not extracted from a library (see README.md "Ports").
// DeepSeek multi-head latent attention (MLA), decode step, dense: every head of every sequence attends to
// that sequence's latent KV cache, which all heads share. Semantics of FlashMLA's dense decoding
// (deepseek-ai/FlashMLA, flash_mla_with_kvcache: q [batch, 1, num_heads, 576], k cache [.., 576],
// head_dim_v = 512, softmax_scale = 576^-0.5): the score uses all 576 dims of the cache row (512 latent +
// 64 RoPE), the output averages its first 512 dims, and lse is returned. Here the cache is contiguous
// [batch, S, 576] with the same length S for every sequence (no paging, no per-sequence lengths), float32.
// One block of 256 threads per (head, sequence); online softmax of attn_port.h.
#include "attn_port.h"

#define D_QK 576
#define D_V 512

extern "C" __global__ void mla_decode(const float* q, const float* kv_cache, float* out, float* lse,
                                      int num_heads, int kv_len, float scale) {
  const int h = blockIdx.x, b = blockIdx.y;
  const float* kv = kv_cache + (size_t)b * kv_len * D_QK;
  const size_t row = (size_t)b * num_heads + h;
  online_softmax_row<D_QK, D_V, 256>(q + row * D_QK, kv, D_QK, kv, D_QK, kv_len, scale, out + row * D_V,
                                     lse + row);
}
