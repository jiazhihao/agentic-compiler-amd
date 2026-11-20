// PORT: written for this benchmark, not extracted from a library (see README.md "Ports").
// Single-query (decode step) attention over a contiguous KV cache with grouped queries: for every query
// head h, o[h] = softmax_j(scale * q[h] . k[j, h / group]) v[j, h / group] and lse[h], with the online
// softmax of attn_port.h. This is the computation of FlashInfer's single_decode_with_kv_cache
// (include/flashinfer/attention/decode.cuh, SingleDecodeWithKVCacheKernel), whose kernel is built on
// cp.async staging, permuted shared memory and variant templates and could not be extracted without
// rewriting most of it; this port keeps its layouts (q [Hq, d], k / v [S, Hkv, d], o [Hq, d], lse [Hq]) but
// not its code, and lse is a natural logarithm (FlashInfer's is base 2). d = 128; one block of 128 threads
// per query head.
#include "attn_port.h"

#define D 128

extern "C" __global__ void attn_decode(const float* q, const float* k, const float* v, float* o, float* lse,
                                       int kv_len, int num_kv_heads, int group_size, float scale) {
  const int h = blockIdx.x;
  const int kv_head = h / group_size;
  const size_t stride = (size_t)num_kv_heads * D;
  online_softmax_row<D, D, D>(q + (size_t)h * D, k + (size_t)kv_head * D, stride, v + (size_t)kv_head * D, stride,
                              kv_len, scale, o + (size_t)h * D, lse + h);
}
