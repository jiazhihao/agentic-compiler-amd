// From rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// rocblas_gemvn_kernel<DIM_X = 64, DIM_Y = 16, T_Index = rocblas_int> + rocblas_gemvn_kernel_calc (the
// variant for every type but double complex), projects/rocblas/library/src/blas2/gemv_device.hpp, with
// Ti = Tex = To = float: the launcher's last branch in projects/rocblas/library/src/blas2/rocblas_gemv_kernels.cpp
// (float, no transpose, a device that is not gfx906 / gfx908 / gfx90a / gfx942 / gfx11 / gfx12, a matrix
// that is neither "skinny m" nor n <= 128 with m >= 2048 n).
// Non-batched, unit increments, alpha and beta by value: the batch loop, load_ptr_batch, load_scalar,
// shift, stride and inc arguments are removed.
#include "rocblas_common.h"

#define DIM_X 64
#define DIM_Y 16
typedef rocblas_int T_Index;

__device__ __attribute__((always_inline)) void rocblas_gemvn_kernel_calc(rocblas_int  m,
                                                                         rocblas_int  n,
                                                                         float        alpha,
                                                                         const float* A,
                                                                         T_Index      lda,
                                                                         const float* x,
                                                                         float        beta,
                                                                         float*       y)
{
    rocblas_int thread_id = threadIdx.x + threadIdx.y * DIM_X;

    if(!alpha)
    {
        if(thread_id < DIM_X * 4)
        {
            int64_t ind = blockIdx.x * DIM_X * 4 + thread_id;
            if(ind < m)
                y[ind] = beta ? (float)(beta * y[ind]) : (float)0;
        }
        return;
    }

    // threads are all configurated locally
    rocblas_int tx = threadIdx.x;
    rocblas_int ty = threadIdx.y;

    rocblas_int ind;

    __shared__ float sdata[DIM_X * 4 * DIM_Y];

    float res_A[4];
    float res_x[4];

    res_A[0] = res_A[1] = res_A[2] = res_A[3] = float{0};

    ind = blockIdx.x * DIM_X * 4 + tx;

    rocblas_int n_tail = n % (4 * DIM_Y);
    rocblas_int col;

    for(col = ty * 4; col < (n - n_tail); col += 4 * DIM_Y)
    {
        res_x[0] = x[(col + 0)];
        res_x[1] = x[(col + 1)];
        res_x[2] = x[(col + 2)];
        res_x[3] = x[(col + 3)];

        if(ind < m)
        {
            res_A[0] += A[ind + (col + 0) * T_Index(lda)] * res_x[0];
            res_A[0] += A[ind + (col + 1) * T_Index(lda)] * res_x[1];
            res_A[0] += A[ind + (col + 2) * T_Index(lda)] * res_x[2];
            res_A[0] += A[ind + (col + 3) * T_Index(lda)] * res_x[3];

            if(ind + DIM_X < m)
            {
                res_A[1] += A[ind + DIM_X + (col + 0) * T_Index(lda)] * res_x[0];
                res_A[1] += A[ind + DIM_X + (col + 1) * T_Index(lda)] * res_x[1];
                res_A[1] += A[ind + DIM_X + (col + 2) * T_Index(lda)] * res_x[2];
                res_A[1] += A[ind + DIM_X + (col + 3) * T_Index(lda)] * res_x[3];

                if(ind + 2 * DIM_X < m)
                {
                    res_A[2] += A[ind + 2 * DIM_X + (col + 0) * T_Index(lda)] * res_x[0];
                    res_A[2] += A[ind + 2 * DIM_X + (col + 1) * T_Index(lda)] * res_x[1];
                    res_A[2] += A[ind + 2 * DIM_X + (col + 2) * T_Index(lda)] * res_x[2];
                    res_A[2] += A[ind + 2 * DIM_X + (col + 3) * T_Index(lda)] * res_x[3];

                    if(ind + 3 * DIM_X < m)
                    {
                        res_A[3] += A[ind + 3 * DIM_X + (col + 0) * T_Index(lda)] * res_x[0];
                        res_A[3] += A[ind + 3 * DIM_X + (col + 1) * T_Index(lda)] * res_x[1];
                        res_A[3] += A[ind + 3 * DIM_X + (col + 2) * T_Index(lda)] * res_x[2];
                        res_A[3] += A[ind + 3 * DIM_X + (col + 3) * T_Index(lda)] * res_x[3];
                    }
                }
            }
        }
    }

    // if n is not multiple of (DIM_Y * 4)
    if(n_tail > 0)
    {
        res_x[0] = res_x[1] = res_x[2] = res_x[3] = float{0};

        if(col + 0 < n)
        {
            res_x[0] = x[(col + 0)];

            if(col + 1 < n)
            {
                res_x[1] = x[(col + 1)];

                if(col + 2 < n)
                {
                    res_x[2] = x[(col + 2)];

                    if(col + 3 < n)
                        res_x[3] = x[(col + 3)];
                }
            }
        }

        if(ind < m)
        {
            res_A[0] += A[ind + (col + 0) * T_Index(lda) * (col + 0 < n)] * res_x[0];
            res_A[0] += A[ind + (col + 1) * T_Index(lda) * (col + 1 < n)] * res_x[1];
            res_A[0] += A[ind + (col + 2) * T_Index(lda) * (col + 2 < n)] * res_x[2];
            res_A[0] += A[ind + (col + 3) * T_Index(lda) * (col + 3 < n)] * res_x[3];

            if(ind + DIM_X < m)
            {
                res_A[1] += A[ind + DIM_X + (col + 0) * T_Index(lda) * (col + 0 < n)] * res_x[0];
                res_A[1] += A[ind + DIM_X + (col + 1) * T_Index(lda) * (col + 1 < n)] * res_x[1];
                res_A[1] += A[ind + DIM_X + (col + 2) * T_Index(lda) * (col + 2 < n)] * res_x[2];
                res_A[1] += A[ind + DIM_X + (col + 3) * T_Index(lda) * (col + 3 < n)] * res_x[3];

                if(ind + 2 * DIM_X < m)
                {
                    res_A[2]
                        += A[ind + 2 * DIM_X + (col + 0) * T_Index(lda) * (col + 0 < n)] * res_x[0];
                    res_A[2]
                        += A[ind + 2 * DIM_X + (col + 1) * T_Index(lda) * (col + 1 < n)] * res_x[1];
                    res_A[2]
                        += A[ind + 2 * DIM_X + (col + 2) * T_Index(lda) * (col + 2 < n)] * res_x[2];
                    res_A[2]
                        += A[ind + 2 * DIM_X + (col + 3) * T_Index(lda) * (col + 3 < n)] * res_x[3];

                    if(ind + 3 * DIM_X < m)
                    {
                        res_A[3] += A[ind + 3 * DIM_X + (col + 0) * T_Index(lda) * (col + 0 < n)]
                                    * res_x[0];
                        res_A[3] += A[ind + 3 * DIM_X + (col + 1) * T_Index(lda) * (col + 1 < n)]
                                    * res_x[1];
                        res_A[3] += A[ind + 3 * DIM_X + (col + 2) * T_Index(lda) * (col + 2 < n)]
                                    * res_x[2];
                        res_A[3] += A[ind + 3 * DIM_X + (col + 3) * T_Index(lda) * (col + 3 < n)]
                                    * res_x[3];
                    }
                }
            }
        }
    }

    sdata[tx + ty * DIM_X * 4]             = res_A[0];
    sdata[tx + DIM_X + ty * DIM_X * 4]     = res_A[1];
    sdata[tx + 2 * DIM_X + ty * DIM_X * 4] = res_A[2];
    sdata[tx + 3 * DIM_X + ty * DIM_X * 4] = res_A[3];

    __syncthreads();

    if(thread_id < DIM_X * 4)
    {
        for(rocblas_int i = 1; i < DIM_Y; i++)
            sdata[thread_id] += sdata[thread_id + DIM_X * 4 * i];

        ind = blockIdx.x * DIM_X * 4 + thread_id;

        if(ind < m)
            y[ind] = beta ? (float)(alpha * sdata[thread_id] + beta * y[ind])
                          : (float)(alpha * sdata[thread_id]);
    }
}

extern "C" __global__ __launch_bounds__(DIM_X* DIM_Y) void rb_gemvn(rocblas_int  m,
                                                                    rocblas_int  n,
                                                                    float        alpha,
                                                                    const float* A,
                                                                    T_Index      lda,
                                                                    const float* x,
                                                                    float        beta,
                                                                    float*       y)
{
    rocblas_int num_threads = blockDim.x * blockDim.y * blockDim.z;
    if(DIM_X * DIM_Y != num_threads)
        return; // need to launch exactly the same number of threads as template parameters indicate

    if(!alpha && beta == 1)
    {
        return;
    }

    rocblas_gemvn_kernel_calc(m, n, alpha, A, lda, x, beta, y);
}
