#include "rocblas_common.h"

#ifndef NBX
#define NBX 256
#endif
#ifndef UNR
#define UNR 8
#endif
#ifndef NC
#define NC 1
#endif
typedef float f4 __attribute__((ext_vector_type(4), aligned(4)));

extern "C" __global__ __launch_bounds__(NBX) void rb_gemvt(rocblas_int  m,
                                                            rocblas_int  n,
                                                            float        alpha,
                                                            const float* A,
                                                            rocblas_int  lda,
                                                            const float* x,
                                                            float        beta,
                                                            float*       y)
{
    if(!alpha && beta == 1)
        return;
    rocblas_int tx   = threadIdx.x;
    rocblas_int col0 = blockIdx.x * NC;
    if(!alpha)
    {
        if(tx == 0)
        {
            for(int c = 0; c < NC; c++)
                if(col0 + c < n)
                    y[col0 + c] = beta ? (float)(beta * y[col0 + c]) : (float)0;
        }
        return;
    }
    const float* Ac[NC];
#pragma unroll
    for(int c = 0; c < NC; c++)
    {
        rocblas_int cc = col0 + c < n ? col0 + c : n - 1;
        Ac[c]          = A + cc * size_t(lda);
    }

    __shared__ float sdata[NC][NBX];
    __shared__ float sdata2[NC][16];

    f4 acc[NC];
#pragma unroll
    for(int c = 0; c < NC; c++)
        acc[c] = (f4){0, 0, 0, 0};
    rocblas_int i = tx * 4;
    const rocblas_int S = NBX * 4;
    for(; i + (UNR - 1) * S + 4 <= m; i += UNR * S)
    {
        f4 a[NC][UNR], b[UNR];
#pragma unroll
        for(int k = 0; k < UNR; k++)
        {
            b[k] = *(const f4*)(x + i + k * S);
#pragma unroll
            for(int c = 0; c < NC; c++)
                a[c][k] = *(const f4*)(Ac[c] + i + k * S);
        }
#pragma unroll
        for(int k = 0; k < UNR; k++)
#pragma unroll
            for(int c = 0; c < NC; c++)
                acc[c] += a[c][k] * b[k];
    }
    for(; i + 4 <= m; i += S)
    {
        f4 b = *(const f4*)(x + i);
#pragma unroll
        for(int c = 0; c < NC; c++)
            acc[c] += *(const f4*)(Ac[c] + i) * b;
    }
    float res[NC];
#pragma unroll
    for(int c = 0; c < NC; c++)
        res[c] = (acc[c].x + acc[c].y) + (acc[c].z + acc[c].w);
    for(; i < m; i++)
    {
        float b = x[i];
#pragma unroll
        for(int c = 0; c < NC; c++)
            res[c] += Ac[c][i] * b;
    }

#pragma unroll
    for(int c = 0; c < NC; c++)
        sdata[c][tx] = res[c];
    __syncthreads();
    if(tx < 16)
    {
#pragma unroll
        for(int c = 0; c < NC; c++)
        {
            float s = 0;
#pragma unroll
            for(int j = 0; j < NBX / 16; j++)
                s += sdata[c][tx + 16 * j];
            sdata2[c][tx] = s;
        }
    }
    __syncthreads();
    if(tx < NC && col0 + tx < n)
    {
        float s = 0;
#pragma unroll
        for(int j = 0; j < 16; j++)
            s += sdata2[tx][j];
        rocblas_int col = col0 + tx;
        y[col] = beta ? (float)(alpha * s + beta * y[col]) : (float)(alpha * s);
    }
}
