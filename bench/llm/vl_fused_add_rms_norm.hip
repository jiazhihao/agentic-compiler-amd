// From vLLM (vllm-project/vllm @ efb6ed2fe36a, Apache-2.0; see LICENSES.md and README.md).
// vllm::fused_add_rms_norm_kernel<scalar_t = float, width = 0, HasWeight = true> (the generic kernel: the
// packed FP16 / BF16 specialization does not exist for float), csrc/layernorm_kernels.cu (the launcher
// fused_add_rms_norm: block = min(hidden_size, 256) for num_tokens >= 256, one block per token).
// Nothing removed.
#include "vllm_common.h"

typedef float scalar_t;
static constexpr bool HasWeight = true;

extern "C" __global__ void vl_fused_add_rms_norm(
    scalar_t* __restrict__ input,  // [..., hidden_size]
    const int64_t input_stride,
    scalar_t* __restrict__ residual,      // [..., hidden_size]
    const scalar_t* __restrict__ weight,  // [hidden_size], null if !HasWeight
    const float epsilon, const int num_tokens, const int hidden_size,
    const int64_t residual_stride) {
  __shared__ float s_variance;
  float variance = 0.0f;

  for (int idx = threadIdx.x; idx < hidden_size; idx += blockDim.x) {
    scalar_t z = input[blockIdx.x * input_stride + idx];
    z += residual[blockIdx.x * residual_stride + idx];
    float x = (float)z;
    variance += x * x;
    residual[blockIdx.x * residual_stride + idx] = z;
  }

  using BlockReduce = cub::BlockReduce<float, 1024>;
  __shared__ typename BlockReduce::TempStorage reduceStore;
  variance = BlockReduce(reduceStore).Reduce(variance, CubAddOp{}, blockDim.x);

  if (threadIdx.x == 0) {
    s_variance = rsqrtf(variance / hidden_size + epsilon);
  }
  __syncthreads();

  for (int idx = threadIdx.x; idx < hidden_size; idx += blockDim.x) {
    float x = (float)residual[blockIdx.x * residual_stride + idx];
    if constexpr (HasWeight) {
      float w = (float)weight[idx];
      input[blockIdx.x * input_stride + idx] = (scalar_t)(x * s_variance * w);
    } else {
      input[blockIdx.x * input_stride + idx] = (scalar_t)(x * s_variance);
    }
  }
}
