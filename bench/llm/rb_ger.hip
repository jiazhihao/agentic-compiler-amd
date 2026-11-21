// From rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// rocblas_sger_kernel<DIM_X = 1024, T = float>, projects/rocblas/library/src/blas2/rocblas_ger_kernels.hpp
// (the launcher's choice for float, m > 1024, on a device that is not gfx90a / gfx942).
// Non-batched, unit increments, alpha by value: the batch loop, load_ptr_batch, load_scalar, shift,
// stride and inc arguments are removed.
#include "rocblas_common.h"

#define DIM_X 1024

extern "C" __global__ __launch_bounds__(DIM_X) void rb_ger(rocblas_int m,
                                                           rocblas_int n,
                                                           float       alpha,
                                                           const float* __restrict__ x,
                                                           const float* __restrict__ y,
                                                           float* __restrict__ A,
                                                           size_t lda)
{
    rocblas_int tx  = threadIdx.x;
    rocblas_int col = blockIdx.x;

    if(!alpha)
    {
        return;
    }

    if(tx < m)
        A += tx;

    //Each blockIdx.x takes care of the computation of each column of matrix 'A'
    A += col * size_t(lda);

    const float res_y = y[col] * alpha;

    //scalar-vector-vector product and add the result to a Hermitian matrix 'A'.
    //If m > DIM_X, then the threads are reused and the multiplied values will be accumalated to Hermitian matrix 'A'.

    for(rocblas_int i = 0; tx + i < m; i += DIM_X)
    {
        A[i] += res_y * x[tx + i];
    }
}
