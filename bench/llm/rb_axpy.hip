// From rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// rocblas_saxpy_2_kernel<NB = ROCBLAS_AXPY_NB = 256, Tex = float>,
// projects/rocblas/library/src/blas1/rocblas_axpy_kernels.hpp
// Non-batched, alpha by value (host pointer mode): the batch loop, load_ptr_batch, load_scalar,
// offset and stride arguments are removed.
#include "rocblas_common.h"

#define NB 256

extern "C" __global__ __launch_bounds__(NB) void rb_axpy(rocblas_int n,
                                                         float       alpha,
                                                         const float* __restrict__ x,
                                                         float* __restrict__ y)
{
    int64_t tid = (blockIdx.x * NB + threadIdx.x) * 2;

    if(alpha)
    {
        auto* tx = x;
        auto* ty = y;

        if(tid < n - 1)
        {
            // Each thread access contiguous elements for example Thread '0' access indices '0' and '1' of the vectors `x` and `y`
            for(int j = 0; j < 2; ++j)
            {
                ty[tid + j] = ty[tid + j] + float(alpha) * tx[tid + j];
            }
        }

        // If `n` is odd then the computation of last element in the vectors is covered below.
        if(n % 2 != 0 && tid == n - 1)
        {
            ty[tid] = ty[tid] + float(alpha) * tx[tid];
        }
    }
}
