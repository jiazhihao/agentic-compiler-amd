#include "rocblas_common.h"

extern "C" __global__ __launch_bounds__(BLK) void rb_ger(rocblas_int m,
                                                           rocblas_int n,
                                                           float       alpha,
                                                           const float* __restrict__ x,
                                                           const float* __restrict__ y,
                                                           float* __restrict__ A,
                                                           size_t lda)
{
    if(!alpha)
        return;
    rocblas_int col = blockIdx.y;
    rocblas_int i0  = (blockIdx.x * BLK + threadIdx.x) * EPT;
    if(i0 >= m)
        return;
    float* __restrict__ a = A + col * size_t(lda) + i0;
    const float* __restrict__ xp = x + i0;
    const float res_y = y[col] * alpha;
    if(i0 + EPT <= m)
    {
        float xv[EPT], av[EPT];
        for(int k = 0; k < EPT; k++) xv[k] = xp[k];
        for(int k = 0; k < EPT; k++) av[k] = a[k];
        for(int k = 0; k < EPT; k++) av[k] += res_y * xv[k];
        for(int k = 0; k < EPT; k++) a[k] = av[k];
    }
    else
    {
        for(int k = 0; i0 + k < m; k++)
            a[k] += res_y * xp[k];
    }
}
