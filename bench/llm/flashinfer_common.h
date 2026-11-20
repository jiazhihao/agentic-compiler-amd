// Device helpers from FlashInfer (flashinfer-ai/flashinfer @ 5cd7ab08e2a7, Apache-2.0; see LICENSES.md)
// for DType = float. Sources:
//   include/flashinfer/vec_dtypes.cuh      (FLASHINFER_INLINE, vec_t<float, 4 or more>; cast_load / cast_store
//                                           of a float vector from / to float are load / store)
//   include/flashinfer/utils.cuh           (ceil_div)
//   include/flashinfer/layout.cuh          (get_elem_offset_impl)
//   include/flashinfer/attention/state.cuh (state_t)
//   include/flashinfer/math.cuh            (inf, ptx_exp2, ptx_log2, shfl_xor_sync, rsqrt, tanh)
// math.cuh wraps NVIDIA PTX instructions in inline asm; here each wrapper calls the HIP equivalent:
//   ex2.approx.ftz.f32 -> exp2f, lg2.approx.ftz.f32 -> log2f, rsqrt.approx.ftz.f32 -> rsqrtf,
//   tanh.approx.f32 -> tanhf, shfl.sync.bfly.b32 -> __shfl_xor.
// FlashInfer's kernels assume 32-lane warps (blockDim.x = 32 or a divisor, `warp_size = 32`). On a wave64
// device a wavefront holds two such rows; __shfl_xor with a lane mask below 32 stays inside a row, so the
// 32-lane reductions are unchanged.
#pragma once
#include <hip/hip_runtime.h>
#include <cstddef>
#include <cstdint>
#include <limits>

#define FLASHINFER_INLINE inline __attribute__((always_inline)) __device__

namespace flashinfer {

template <typename T1, typename T2>
__forceinline__ __device__ __host__ constexpr T1 ceil_div(const T1 x, const T2 y) noexcept {
  return (x + y - 1) / y;
}

__host__ __device__ __forceinline__ size_t get_elem_offset_impl(size_t elem_idx, size_t head_idx,
                                                                size_t feat_idx, size_t stride_n,
                                                                size_t stride_h) {
  return elem_idx * stride_n + head_idx * stride_h + feat_idx;
}

namespace math {

constexpr float inf = std::numeric_limits<float>::infinity();

__forceinline__ __device__ float ptx_exp2(float x) { return exp2f(x); }
__forceinline__ __device__ float ptx_log2(float x) { return log2f(x); }
__forceinline__ __device__ float shfl_xor_sync(float x, int lane_mask) { return __shfl_xor(x, lane_mask); }
__forceinline__ __device__ float rsqrt(float x) { return rsqrtf(x); }
__forceinline__ __device__ float tanh(float x) { return tanhf(x); }

}  // namespace math

template <typename float_t, size_t vec_size>
struct vec_t;

// float x 4 or more
template <size_t vec_size>
struct vec_t<float, vec_size> {
  static_assert(vec_size % 4 == 0, "Invalid vector size");
  float4 data[vec_size / 4];

  FLASHINFER_INLINE float& operator[](size_t i) { return ((float*)(data))[i]; }
  FLASHINFER_INLINE const float& operator[](size_t i) const { return ((const float*)(data))[i]; }
  FLASHINFER_INLINE float* ptr() { return reinterpret_cast<float*>(&data); }
  FLASHINFER_INLINE void fill(float val) {
#pragma unroll
    for (size_t i = 0; i < vec_size / 4; ++i) {
      data[i] = make_float4(val, val, val, val);
    }
  }
  FLASHINFER_INLINE void load(const float* ptr) {
#pragma unroll
    for (size_t i = 0; i < vec_size / 4; ++i) {
      data[i] = ((float4*)ptr)[i];
    }
  }
  FLASHINFER_INLINE void store(float* ptr) const {
#pragma unroll
    for (size_t i = 0; i < vec_size / 4; ++i) {
      ((float4*)ptr)[i] = data[i];
    }
  }
  FLASHINFER_INLINE void cast_load(const float* ptr) { load(ptr); }
  FLASHINFER_INLINE void cast_store(float* ptr) const { store(ptr); }
};

template <size_t vec_size>
struct state_t {
  /* the weighted sum of v: exp(pre-softmax logit - m) * v / d  */
  vec_t<float, vec_size> o;
  /* maximum value of pre-softmax logits */
  float m;
  /* sum of exp(pre-softmax logits - m) */
  float d;

  __device__ __forceinline__ void init() {
    o.fill(0.f);
    m = -math::inf;
    d = 1.f;
  }

  __device__ __forceinline__ state_t() { init(); }

  __device__ __forceinline__ float get_lse() const { return m + math::ptx_log2(d); }

  __device__ __forceinline__ void merge(const vec_t<float, vec_size>& other_o, float other_m,
                                        float other_d) {
    float m_prev = m, d_prev = d;
    m = max(m_prev, other_m);
    // max() drops the NaN from merging two empty states ((-inf) - (-inf)).
    float f1 = math::ptx_exp2(max(m_prev - m, -math::inf));
    float f2 = math::ptx_exp2(max(other_m - m, -math::inf));
    d = d_prev * f1 + other_d * f2;
#pragma unroll
    for (size_t i = 0; i < vec_size; ++i) {
      o[i] = o[i] * f1 + other_o[i] * f2;
    }
  }

  __device__ __forceinline__ void normalize() {
    // only normalize by d when not normalized on the fly; empty states
    // (d == 0) keep zero output instead of 0/0 = NaN
    float d_rcp = (d > 0.f) ? (1.f / d) : 0.f;   // __fdividef(1.f, d)
#pragma unroll
    for (size_t i = 0; i < vec_size; ++i) {
      o[i] = o[i] * d_rcp;
    }
  }
};

}  // namespace flashinfer
