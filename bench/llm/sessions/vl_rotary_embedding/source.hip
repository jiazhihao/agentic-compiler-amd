#include <hip/hip_runtime.h>
#include <cstdint>

typedef float v4f __attribute__((ext_vector_type(4), aligned(4)));

static inline __device__ void rot_group(float* __restrict__ arr, const float* __restrict__ cos_ptr,
                                        const float* __restrict__ sin_ptr, int p0, int embed_dim,
                                        bool inverse) {
  if (p0 + 4 <= embed_dim) {
    v4f c = *(const v4f*)(cos_ptr + p0);
    v4f s = *(const v4f*)(sin_ptr + p0);
    v4f x = *(const v4f*)(arr + p0);
    v4f y = *(const v4f*)(arr + embed_dim + p0);
    if (inverse) s = -s;
    *(v4f*)(arr + p0) = x * c - y * s;
    *(v4f*)(arr + embed_dim + p0) = y * c + x * s;
  } else {
    for (int p = p0; p < embed_dim; ++p) {
      float c = cos_ptr[p], s = sin_ptr[p];
      if (inverse) s = -s;
      float x = arr[p], y = arr[embed_dim + p];
      arr[p] = x * c - y * s;
      arr[embed_dim + p] = y * c + x * s;
    }
  }
}

extern "C" __global__ void vl_rotary_embedding(
    const int64_t* __restrict__ positions, float* __restrict__ query, float* __restrict__ key,
    const float* __restrict__ cos_sin_cache, const int rot_dim, const int64_t query_stride,
    const int64_t key_stride, const int64_t head_stride, const int num_heads,
    const int num_kv_heads, const int head_size, const int64_t rope_dim_offset,
    const bool inverse) {
  const int token_idx = blockIdx.x;
  int64_t pos = positions[token_idx];
  const float* cos_ptr = cos_sin_cache + pos * rot_dim;
  const int embed_dim = rot_dim / 2;
  const float* sin_ptr = cos_ptr + embed_dim;
  const unsigned gph = (unsigned)(embed_dim + 3) >> 2;
  const unsigned nqh = (unsigned)num_heads;
  const unsigned nh = nqh + (key != nullptr ? (unsigned)num_kv_heads : 0u);
  const unsigned total = nh * gph;
  const unsigned step = gridDim.y * blockDim.x;
  for (unsigned i = blockIdx.y * blockDim.x + threadIdx.x; i < total; i += step) {
    unsigned head = i / gph;
    int p0 = (int)(i - head * gph) * 4;
    float* arr;
    if (head < nqh)
      arr = query + (token_idx * query_stride + (int64_t)head * head_stride + rope_dim_offset);
    else
      arr = key + (token_idx * key_stride + (int64_t)(head - nqh) * head_stride + rope_dim_offset);
    rot_group(arr, cos_ptr, sin_ptr, p0, embed_dim, inverse);
  }
}
