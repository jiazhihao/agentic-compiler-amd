// From rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// rocblas_scopy_2_kernel<DIM_X = ROCBLAS_COPY_NB = 256>, projects/rocblas/library/src/blas1/rocblas_copy_kernels.hpp
// T = float, non-batched: the batch loop, load_ptr_batch, shift and stride arguments are removed.
#include "rocblas_common.h"

#define DIM_X 256

extern "C" __global__ __launch_bounds__(DIM_X) void rb_copy(rocblas_int n,
                                                            const float* __restrict__ x,
                                                            float* __restrict__ y)
{
    int64_t tid = (blockIdx.x * DIM_X + threadIdx.x) * 2;

    if(tid < n - 1)
    {
        for(int j = 0; j < 2; ++j)
        {
            y[tid + j] = x[tid + j];
        }
    }
    if(n % 2 != 0 && tid == n - 1)
        y[tid] = x[tid];
}
