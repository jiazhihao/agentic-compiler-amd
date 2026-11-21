// From rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// rocblas_sscal_2_kernel<DIM_X = ROCBLAS_SCAL_NB = 256, T = float, Tex = float, Ta = float, Tx = float*>,
// projects/rocblas/library/src/blas1/rocblas_scal_kernels.hpp
// Non-batched, alpha by value (host pointer mode): the batch loop, load_ptr_batch, load_scalar,
// offset and stride arguments are removed.
#include "rocblas_common.h"

#define DIM_X 256

extern "C" __global__ __launch_bounds__(DIM_X) void rb_scal(rocblas_int n, float alpha, float* __restrict__ x)
{
    uint32_t tid = (blockIdx.x * DIM_X + threadIdx.x) * 2;

    if(alpha != 1)
    {
        if(tid + 1 < n)
        {
            // Each thread access contiguous elements for example Thread '0' access indices '0' and '1' of the vector `x`
            for(int32_t j = 0; j < 2; ++j)
            {
                float res  = (float)x[tid + j] * alpha;
                x[tid + j] = (float)res;
            }
        }

        // If `n` is odd then the computation of last element in the vector `x` is covered below.
        if(n % 2 != 0 && tid == n - 1)
        {
            float res = (float)x[tid] * alpha;
            x[tid]    = (float)res;
        }
    }
}
