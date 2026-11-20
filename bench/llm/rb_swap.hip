// From rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// rocblas_sswap_2_kernel<DIM_X = ROCBLAS_SWAP_NB = 256> and rocblas_swap_vals,
// projects/rocblas/library/src/blas1/rocblas_swap_kernels.hpp
// T = float, non-batched: the batch loop, load_ptr_batch, offset and stride arguments are removed.
#include "rocblas_common.h"

#define DIM_X 256

template <typename T>
__forceinline__ __device__ void rocblas_swap_vals(T* __restrict__ x, T* __restrict__ y)
{
    T tmp = *y;
    *y    = *x;
    *x    = tmp;
}

extern "C" __global__ __launch_bounds__(DIM_X) void rb_swap(rocblas_int n,
                                                            float* __restrict__ x,
                                                            float* __restrict__ y)
{
    int64_t tid = (blockIdx.x * DIM_X + threadIdx.x) * 2;

    if(tid < n - 1)
    {
        for(int j = 0; j < 2; ++j)
        {
            rocblas_swap_vals(x + tid + j, y + tid + j);
        }
    }
    if(n % 2 != 0 && tid == n - 1)
    {
        rocblas_swap_vals(x + tid, y + tid);
    }
}
