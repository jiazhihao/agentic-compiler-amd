#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>

#define MAX_K 16
#define L2E 1.4426950408889634f

typedef long long i64;
static __device__ __forceinline__ int f2key(float x) {
  int b = __builtin_bit_cast(int, x + 0.0f);
  return b ^ ((b >> 31) & 0x7fffffff);
}
static __device__ __forceinline__ float key2f(int k) {
  return __builtin_bit_cast(float, k ^ ((k >> 31) & 0x7fffffff));
}
static __device__ __forceinline__ bool gt(int ka, unsigned la, int kb, unsigned lb) {
  return (i64)(((unsigned long long)(unsigned)ka << 32) | la) > (i64)(((unsigned long long)(unsigned)kb << 32) | lb);
}
// element X = (k##X: key, l##X: ~index); one 64-bit compare, four 32-bit selects
#define CS(a, b) { bool c_ = gt(k##a, l##a, k##b, l##b); int hk = c_ ? k##a : k##b; int lk = c_ ? k##b : k##a; \
    unsigned hl = c_ ? l##a : l##b; unsigned ll = c_ ? l##b : l##a; k##a = hk; k##b = lk; l##a = hl; l##b = ll; }
#define MX(a, b) { bool c_ = gt(k##a, l##a, k##b, l##b); k##a = c_ ? k##a : k##b; l##a = c_ ? l##a : l##b; }
#define EX(a) __builtin_amdgcn_exp2f(((a) - m) * L2E)

#define MERGE() \
  CS(c0, c2) CS(c1, c3) CS(c4, c6) CS(c5, c7) \
  CS(c0, c4) CS(c1, c5) CS(c2, c6) CS(c3, c7) \
  CS(c0, c1) CS(c2, c3) CS(c4, c5) CS(c6, c7) \
  CS(c2, c4) CS(c3, c5) \
  CS(c1, c4) CS(c3, c6) \
  CS(c1, c2) CS(c3, c4) CS(c5, c6) \
  MX(t0, c7) MX(t1, c6) MX(t2, c5) MX(t3, c4) MX(t4, c3) MX(t5, c2) MX(t6, c1) MX(t7, c0) \
  CS(t0, t4) CS(t1, t5) CS(t2, t6) CS(t3, t7) \
  CS(t0, t2) CS(t1, t3) CS(t4, t6) CS(t5, t7) \
  CS(t0, t1) CS(t2, t3) CS(t4, t5) CS(t6, t7)

extern "C" __global__ void moe_gate_topk(const float* logits, float* weights, int32_t* indices, int num_tokens,
                                         int num_experts, int k) {
  const int t = blockIdx.x * blockDim.x + threadIdx.x;
  if (t >= num_tokens) return;
  const float* x = logits + (size_t)t * num_experts;

  if (k != 8) {
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
    return;
  }

  const int IMIN = (int)0x80000000;
  int kt0 = IMIN, kt1 = IMIN, kt2 = IMIN, kt3 = IMIN, kt4 = IMIN, kt5 = IMIN, kt6 = IMIN, kt7 = IMIN;
  unsigned lt0 = 0, lt1 = 0, lt2 = 0, lt3 = 0, lt4 = 0, lt5 = 0, lt6 = 0, lt7 = 0;
  float m = -INFINITY;
  float sum = 0.0f;
  int e = 0;
  for (; e + 8 <= num_experts; e += 8) {
    float a0 = x[e], a1 = x[e + 1], a2 = x[e + 2], a3 = x[e + 3], a4 = x[e + 4], a5 = x[e + 5], a6 = x[e + 6], a7 = x[e + 7];
    float nm = fmaxf(m, fmaxf(fmaxf(fmaxf(a0, a1), fmaxf(a2, a3)), fmaxf(fmaxf(a4, a5), fmaxf(a6, a7))));
    if (nm > m) sum *= __builtin_amdgcn_exp2f((m - nm) * L2E);
    m = nm;
    sum += ((EX(a0) + EX(a1)) + (EX(a2) + EX(a3))) + ((EX(a4) + EX(a5)) + (EX(a6) + EX(a7)));
    int kc0 = f2key(a0), kc1 = f2key(a1), kc2 = f2key(a2), kc3 = f2key(a3), kc4 = f2key(a4), kc5 = f2key(a5), kc6 = f2key(a6), kc7 = f2key(a7);
    unsigned lc0 = ~e, lc1 = ~(e + 1), lc2 = ~(e + 2), lc3 = ~(e + 3), lc4 = ~(e + 4), lc5 = ~(e + 5), lc6 = ~(e + 6), lc7 = ~(e + 7);
    MERGE()
  }
  if (e < num_experts) {
    int kc0 = IMIN, kc1 = IMIN, kc2 = IMIN, kc3 = IMIN, kc4 = IMIN, kc5 = IMIN, kc6 = IMIN, kc7 = IMIN;
    unsigned lc0 = 0, lc1 = 0, lc2 = 0, lc3 = 0, lc4 = 0, lc5 = 0, lc6 = 0, lc7 = 0;
#define TAIL(i) if (e + i < num_experts) { float a = x[e + i]; float nm = fmaxf(m, a); \
      if (nm > m) sum *= __builtin_amdgcn_exp2f((m - nm) * L2E); m = nm; sum += EX(a); kc##i = f2key(a); lc##i = ~(e + i); }
    TAIL(0) TAIL(1) TAIL(2) TAIL(3) TAIL(4) TAIL(5) TAIL(6)
    MERGE()
  }
  float* w = weights + (size_t)t * 8;
  int32_t* ix = indices + (size_t)t * 8;
  float rs = 1.0f / sum;
#define OUT(j) { int id = ~(int)lt##j; \
    w[j] = (id < 0) ? (__builtin_amdgcn_exp2f((-INFINITY - m) * L2E) * rs) : (__builtin_amdgcn_exp2f((key2f(kt##j) - m) * L2E) * rs); ix[j] = id; }
  OUT(0) OUT(1) OUT(2) OUT(3) OUT(4) OUT(5) OUT(6) OUT(7)
}
