// From vLLM (vllm-project/vllm @ efb6ed2fe36a, Apache-2.0; see LICENSES.md and README.md).
// vllm::rms_norm_kernel<scalar_t = float, VEC_SIZE = 4, NUM_DIMS = 2, HasWeight = true>,
// csrc/layernorm_kernels.cu (the launcher rms_norm: VEC_SIZE = gcd(16 / sizeof(float), hidden_size) = 4,
// block = min(hidden_size / VEC_SIZE, 256) for num_tokens >= 256, one block per token; a 1-D weight, so
// weight_stride = 0). Nothing removed: the NUM_DIMS == 3 / 4 and !HasWeight branches are dead under
// if constexpr.
#include "vllm_common.h"

typedef float scalar_t;
#define VEC_SIZE 4
#define NUM_DIMS 2
static constexpr bool HasWeight = true;

extern "C" __global__ void vl_rms_norm(
    scalar_t* __restrict__ out,           // [..., hidden_size]
    const scalar_t* __restrict__ input,   // [..., hidden_size]
    const int64_t input_stride_d2,        // input.stride(-2)
    const int64_t input_stride_d3,        // input.stride(-3)
    const int64_t input_stride_d4,        // input.stride(-4)
    const int64_t input_shape_d2,         // input.size(-2)
    const int64_t input_shape_d3,         // input.size(-3)
    const scalar_t* __restrict__ weight,  // [hidden_size] or
                                          // [num_groups, hidden_size];
                                          // null if !HasWeight
    const int64_t weight_stride,          // 0 or weight.stride(0)
    const float epsilon, const int num_tokens, const int hidden_size) {
  using vllm::vec_n_t;
  __shared__ float s_variance;
  float variance = 0.0f;
  const scalar_t* input_row;
  const scalar_t* weight_row;
  if constexpr (NUM_DIMS == 2) {
    // 2D for layernorm normal case [batch_size, hidden]
    input_row = input + blockIdx.x * input_stride_d2;
    weight_row = weight + blockIdx.x * weight_stride;
  }

  auto vec_op = [&variance](const vec_n_t<scalar_t, VEC_SIZE>& vec) {
#pragma unroll
    for (int i = 0; i < VEC_SIZE; ++i) {
      float x = static_cast<float>(vec.val[i]);
      variance += x * x;
    }
  };
  auto scalar_op = [&variance](const scalar_t& val) {
    float x = static_cast<float>(val);
    variance += x * x;
  };
  vllm::vectorize_read_with_alignment<VEC_SIZE>(
      input_row, hidden_size, threadIdx.x, blockDim.x, vec_op, scalar_op);

  using BlockReduce = cub::BlockReduce<float, 1024>;
  __shared__ typename BlockReduce::TempStorage reduceStore;
  variance = BlockReduce(reduceStore).Reduce(variance, CubAddOp{}, blockDim.x);

  if (threadIdx.x == 0) {
    s_variance = rsqrtf(variance / hidden_size + epsilon);
  }
  __syncthreads();

  scalar_t* out_row = out + blockIdx.x * hidden_size;
  auto* v_in = reinterpret_cast<const vec_n_t<scalar_t, VEC_SIZE>*>(input_row);
  auto* v_w = reinterpret_cast<const vec_n_t<scalar_t, VEC_SIZE>*>(weight_row);
  auto* v_out = reinterpret_cast<vec_n_t<scalar_t, VEC_SIZE>*>(out_row);
  for (int i = threadIdx.x; i < hidden_size / VEC_SIZE; i += blockDim.x) {
    vec_n_t<scalar_t, VEC_SIZE> dst;
    vec_n_t<scalar_t, VEC_SIZE> src1 = v_in[i];
    vec_n_t<scalar_t, VEC_SIZE> src2;
    if constexpr (HasWeight) {
      src2 = v_w[i];
    }
#pragma unroll
    for (int j = 0; j < VEC_SIZE; j++) {
      float x = static_cast<float>(src1.val[j]);
      if constexpr (HasWeight) {
        float w = static_cast<float>(src2.val[j]);
        dst.val[j] = static_cast<scalar_t>(x * s_variance * w);
      } else {
        dst.val[j] = static_cast<scalar_t>(x * s_variance);
      }
    }
    v_out[i] = dst;
  }
}
