// From FlashInfer (flashinfer-ai/flashinfer @ 5cd7ab08e2a7, Apache-2.0; see LICENSES.md and README.md).
// MergeStatesKernel<vec_size = 4, DTypeIn = float, DTypeO = float>, include/flashinfer/attention/cascade.cuh,
// with state_t from attention/state.cuh (the launcher MergeStates for HEAD_DIM = 128 and
// num_index_sets < seq_len: vec_size = 4, blockDim = (32, num_heads), one block per position).
// Nothing removed.
#include "flashinfer_common.h"

using namespace flashinfer;
#define vec_size 4
typedef float DTypeO;

extern "C" __global__ void fi_merge_states(float* __restrict__ V, float* __restrict__ S,
                                           float* __restrict__ v_merged, float* __restrict__ s_merged,
                                           uint32_t num_index_sets, uint32_t num_heads, uint32_t head_dim) {
  uint32_t tx = threadIdx.x, ty = threadIdx.y;
  uint32_t pos = blockIdx.x;
  uint32_t head_idx = ty;

  if (num_index_sets == 0) {
    vec_t<DTypeO, vec_size> v;
    v.fill(DTypeO(0.f));
    v.store(v_merged + (pos * num_heads + head_idx) * head_dim + tx * vec_size);
    if (tx == 0 && s_merged != nullptr) {
      s_merged[pos * num_heads + head_idx] = -math::inf;
    }
    return;
  }

  if (num_index_sets == 1) {
    vec_t<DTypeO, vec_size> v;
    v.cast_load(V + (pos * num_heads + head_idx) * head_dim + tx * vec_size);
    v.store(v_merged + (pos * num_heads + head_idx) * head_dim + tx * vec_size);
    if (tx == 0 && s_merged != nullptr) {
      s_merged[pos * num_heads + head_idx] = S[pos * num_heads + head_idx];
    }
    return;
  }

  state_t<vec_size> st;
#pragma unroll 2
  for (uint32_t iter = 0; iter < num_index_sets; ++iter) {
    float s = S[(pos * num_index_sets + iter) * num_heads + head_idx];
    vec_t<float, vec_size> v;
    v.cast_load(V + ((pos * num_index_sets + iter) * num_heads + head_idx) * head_dim +
                tx * vec_size);
    st.merge(v, s, 1);
  }

  st.normalize();
  st.o.cast_store(v_merged + (pos * num_heads + head_idx) * head_dim + tx * vec_size);
  if (tx == 0 && s_merged != nullptr) {
    s_merged[pos * num_heads + head_idx] = st.get_lse();
  }
}
