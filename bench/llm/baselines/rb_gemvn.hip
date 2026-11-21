#include "rocblas_common.h"
#ifndef BXX
#define BXX 32
#endif
#ifndef WAV
#define WAV 32
#endif
#ifndef CPI
#define CPI 8
#endif

extern "C" __global__ __launch_bounds__(BXX * WAV) void rb_gemvn(rocblas_int  m,
                                                              rocblas_int  n,
                                                              float        alpha,
                                                              const float* A,
                                                              rocblas_int  lda,
                                                              const float* x,
                                                              float        beta,
                                                              float*       y)
{
    int tx = threadIdx.x, ty = threadIdx.y;
    int r = blockIdx.x * BXX + tx;
    if(!alpha)
    {
        if(beta == 1)
            return;
        if(ty == 0 && r < m)
            y[r] = beta ? (float)(beta * y[r]) : (float)0;
        return;
    }
    __shared__ float sdata[BXX * WAV];
    float acc = 0.f;
    int col = ty * CPI;
    if(r < m)
    {
        const float* a = A + r;
        for(; col + CPI <= n; col += WAV * CPI)
        {
            float t[CPI];
            float xv[CPI];
            for(int j = 0; j < CPI; j++)
                xv[j] = x[col + j];
            for(int j = 0; j < CPI; j++)
                t[j] = a[(int64_t)(col + j) * lda];
            for(int j = 0; j < CPI; j++)
                acc += t[j] * xv[j];
        }
        for(; col < n; col++)
            acc += a[(int64_t)col * lda] * x[col];
    }
    sdata[ty * BXX + tx] = acc;
    __syncthreads();
    if(ty == 0)
    {
        float s = 0.f;
        for(int i = 0; i < WAV; i++)
            s += sdata[i * BXX + tx];
        if(r < m)
            y[r] = beta ? (float)(alpha * s + beta * y[r]) : (float)(alpha * s);
    }
}
