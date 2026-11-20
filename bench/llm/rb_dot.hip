// From rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// rocblas_dot_kernel_inc1<ONE_BLOCK = false, NB = ROCBLAS_DOT_NB = 512, WIN = rocblas_dot_WIN<float>() = 4,
// CONJ = false, T = U-elem = V = float> + rocblas_dot_save_sum,
// projects/rocblas/library/src/blas1/rocblas_dot_kernels.hpp
// First-stage kernel only (the partial sums per block; rocblas_reduction_kernel_part2 finishes them).
// Non-batched: the batch loop, load_ptr_batch, shift and stride arguments are removed (batch = 0).
#include "rocblas_common.h"

#define NB 512
#define WIN 4
static constexpr bool ONE_BLOCK = false;

__inline__ __device__ void rocblas_dot_save_sum(float sum, float* __restrict__ workspace, float* __restrict__ out)
{
    if(threadIdx.x == 0)
    {
        if(ONE_BLOCK || gridDim.x == 1) // small N avoid second kernel
            out[0] = float(sum);
        else
            workspace[blockIdx.x] = sum;
    }
}

extern "C" __global__ __launch_bounds__(NB) void rb_dot(rocblas_int n,
                                                        const float* __restrict__ x,
                                                        const float* __restrict__ y,
                                                        float* __restrict__ workspace,
                                                        float* __restrict__ out)
{
    const int i0 = !ONE_BLOCK ? blockIdx.x * NB + threadIdx.x : threadIdx.x;

    float sum = 0;

    // sum WIN elements per thread
    int inc = !ONE_BLOCK ? NB * gridDim.x : NB;
    int i   = i0;
    for(int j = 0; j < WIN && i < n; j++, i += inc)
    {
        sum += float(y[i]) * float(x[i]);
    }

    if(warpSize == WARP_32)
        sum = rocblas_dot_block_reduce<WARP_32, NB>(sum);
    else
        sum = rocblas_dot_block_reduce<WARP_64, NB>(sum);

    rocblas_dot_save_sum(sum, workspace, out);
}
