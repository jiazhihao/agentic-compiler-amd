// From rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// rocblas_gemvt_kernel<CONJ = false, NB_X = 256> + rocblas_gemvt_kernel_calc + rocblas_sum_reduce,
// projects/rocblas/library/src/blas2/gemv_device.hpp (Ti = Tex = To = float): the launcher's choice in
// projects/rocblas/library/src/blas2/rocblas_gemv_kernels.cpp for float, transpose, on a device that is
// not gfx908 / gfx942 / gfx10-12, with one block per column (grid.x = n).
// Non-batched, unit increments, alpha and beta by value: the batch loop, load_ptr_batch, load_scalar,
// shift, stride and inc arguments are removed.
#include "rocblas_common.h"

#define NB_X 256
static constexpr bool CONJ = false;

__device__ __attribute__((always_inline)) void rocblas_gemvt_kernel_calc(rocblas_int  m,
                                                                         rocblas_int  n,
                                                                         float        alpha,
                                                                         const float* A,
                                                                         rocblas_int  lda,
                                                                         const float* x,
                                                                         float        beta,
                                                                         float*       y)
{
    rocblas_int tx  = threadIdx.x;
    rocblas_int col = blockIdx.x;

    if(!alpha)
    {
        if(tx == 0)
            y[col] = beta ? (float)(beta * y[col]) : (float)0;
        return;
    }

    if(tx < m)
        A += tx;

    A += col * size_t(lda);

    float res = 0;

    __shared__ float sdata[NB_X];

    // partial sums
    rocblas_int m_full = (m / NB_X) * NB_X;

    for(rocblas_int i = 0; i < m_full; i += NB_X)
        res += float(A[i]) * float(x[tx + i]);

    if(tx + m_full < m)
        res += float(A[m_full]) * float(x[tx + m_full]);

    sdata[tx] = res;

    // tree reduction of partial sums,
    if(NB_X > 16)
    {
        rocblas_sum_reduce<NB_X>(tx, sdata);
    }
    else
    {
        __syncthreads();

        if(tx == 0)
        {
            for(rocblas_int i = 1; i < m && i < NB_X; i++)
                sdata[0] += sdata[i];
        }

        __syncthreads();
    }

    if(tx == 0)
    {
        // !alpha handled earlier by early return
        y[col] = beta ? (float)(alpha * sdata[0] + beta * y[col]) : (float)(alpha * sdata[0]);
    }
}

extern "C" __global__ __launch_bounds__(NB_X) void rb_gemvt(rocblas_int  m,
                                                            rocblas_int  n,
                                                            float        alpha,
                                                            const float* A,
                                                            rocblas_int  lda,
                                                            const float* x,
                                                            float        beta,
                                                            float*       y)
{
    if(!alpha && beta == 1)
    {
        return;
    }

    rocblas_gemvt_kernel_calc(m, n, alpha, A, lda, x, beta, y);
}
