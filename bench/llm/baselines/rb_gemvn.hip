#include "rocblas_common.h"
#ifndef R
#define R 4
#endif
#ifndef W
#define W 16
#endif
#ifndef C
#define C 8
#endif

extern "C" __global__ __launch_bounds__(64 * W) void rb_gemvn(rocblas_int  m,
                                                              rocblas_int  n,
                                                              float        alpha,
                                                              const float* A,
                                                              rocblas_int  lda,
                                                              const float* x,
                                                              float        beta,
                                                              float*       y)
{
    int tx = threadIdx.x, ty = threadIdx.y;
    int thread_id = tx + ty * 64;
    int row0 = blockIdx.x * (64 * R);
    if(!alpha)
    {
        if(beta == 1)
            return;
        if(thread_id < 64 * R)
        {
            int ind = row0 + thread_id;
            if(ind < m)
                y[ind] = beta ? (float)(beta * y[ind]) : (float)0;
        }
        return;
    }
    __shared__ float sdata[64 * R * W];
    float acc[R];
    for(int q = 0; q < R; q++)
        acc[q] = 0.f;
    int r = row0 + tx * R;
    int col = ty * C;
    if(r + R <= m)
    {
        const float* a = A + r;
        for(; col + C <= n; col += W * C)
        {
            float t[C][R];
            float xv[C];
            for(int j = 0; j < C; j++)
                xv[j] = x[col + j];
            for(int j = 0; j < C; j++)
                __builtin_memcpy(t[j], a + (int64_t)(col + j) * lda, 4 * R);
            for(int j = 0; j < C; j++)
                for(int q = 0; q < R; q++)
                    acc[q] += t[j][q] * xv[j];
        }
        for(; col < n; col++)
        {
            float xs = x[col];
            for(int q = 0; q < R; q++)
                acc[q] += a[(int64_t)col * lda + q] * xs;
        }
    }
    else if(r < m)
    {
        int cnt = m - r;
        const float* a = A + r;
        for(; col < n; col += W * C)
            for(int j = 0; j < C; j++)
                if(col + j < n)
                {
                    float xs = x[col + j];
                    for(int q = 0; q < cnt; q++)
                        acc[q] += a[(int64_t)(col + j) * lda + q] * xs;
                }
    }
    for(int q = 0; q < R; q++)
        sdata[ty * 64 * R + tx * R + q] = acc[q];
    __syncthreads();
    if(thread_id < 64 * R)
    {
        float s = 0.f;
        for(int i = 0; i < W; i++)
            s += sdata[i * 64 * R + thread_id];
        int ind = row0 + thread_id;
        if(ind < m)
            y[ind] = beta ? (float)(alpha * s + beta * y[ind]) : (float)(alpha * s);
    }
}
