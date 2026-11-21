#include <hip/hip_runtime.h>
#include <cmath>
#include <cstdint>

#define MAX_K 16
#define L2E 1.4426950408889634f

typedef unsigned long long u64;
// (value, index) as one finite double: high word = float bits + 0x00100000 (never a double NaN/inf/denormal for
// non-NaN floats, same sign-magnitude order), low word = ~index for positive values, index for negative ones:
// a larger double is a larger value or, at equal values, a lower index.
static __device__ __forceinline__ double enc(float a, int e) {
  unsigned b = __builtin_bit_cast(unsigned, a + 0.0f);
  unsigned hi = b + 0x00100000u;
  unsigned lo = ~(unsigned)e ^ (unsigned)((int)b >> 31);
  return __builtin_bit_cast(double, ((u64)hi << 32) | lo);
}
#define CS(a, b) { double h_ = __builtin_fmax(a, b); double l_ = __builtin_fmin(a, b); a = h_; b = l_; }
#define MX(a, b) { a = __builtin_fmax(a, b); }
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

  const double SENT = __builtin_bit_cast(double, 0xff900000ffffffffull);
  double t0 = SENT, t1 = SENT, t2 = SENT, t3 = SENT, t4 = SENT, t5 = SENT, t6 = SENT, t7 = SENT;
  float m = -INFINITY;
  float sum = 0.0f;
  int e = 0;
  for (; e + 8 <= num_experts; e += 8) {
    float a0 = x[e], a1 = x[e + 1], a2 = x[e + 2], a3 = x[e + 3], a4 = x[e + 4], a5 = x[e + 5], a6 = x[e + 6], a7 = x[e + 7];
    float nm = fmaxf(m, fmaxf(fmaxf(fmaxf(a0, a1), fmaxf(a2, a3)), fmaxf(fmaxf(a4, a5), fmaxf(a6, a7))));
    if (nm > m) sum *= __builtin_amdgcn_exp2f((m - nm) * L2E);
    m = nm;
    sum += ((EX(a0) + EX(a1)) + (EX(a2) + EX(a3))) + ((EX(a4) + EX(a5)) + (EX(a6) + EX(a7)));
    double c0 = enc(a0, e), c1 = enc(a1, e + 1), c2 = enc(a2, e + 2), c3 = enc(a3, e + 3), c4 = enc(a4, e + 4), c5 = enc(a5, e + 5), c6 = enc(a6, e + 6), c7 = enc(a7, e + 7);
    MERGE()
  }
  if (e < num_experts) {
    double c0 = SENT, c1 = SENT, c2 = SENT, c3 = SENT, c4 = SENT, c5 = SENT, c6 = SENT, c7 = SENT;
#define TAIL(i) if (e + i < num_experts) { float a = x[e + i]; float nm = fmaxf(m, a); \
      if (nm > m) sum *= __builtin_amdgcn_exp2f((m - nm) * L2E); m = nm; sum += EX(a); c##i = enc(a, e + i); }
    TAIL(0) TAIL(1) TAIL(2) TAIL(3) TAIL(4) TAIL(5) TAIL(6)
    MERGE()
  }
  float* w = weights + (size_t)t * 8;
  int32_t* ix = indices + (size_t)t * 8;
  float rs = 1.0f / sum;
#define OUT(j) { u64 q = __builtin_bit_cast(u64, t##j); unsigned b = (unsigned)(q >> 32) - 0x00100000u; \
    int id = (int)(~(unsigned)q ^ (unsigned)((int)b >> 31)); \
    w[j] = __builtin_amdgcn_exp2f((__builtin_bit_cast(float, b) - m) * L2E) * rs; ix[j] = id; }
  OUT(0) OUT(1) OUT(2) OUT(3) OUT(4) OUT(5) OUT(6) OUT(7)
}
