#include "rocblas_common.h"

// block 512: 8 waves; wave w reads 1 KB contiguous: chunk j = w / 2, half h = w % 2, one x4 load per lane
extern "C" __global__ __launch_bounds__(512) void rb_nrm2(rocblas_int n,
                                                         rocblas_int nblocks,
                                                         const float* x,
                                                         float*       workspace)
{
    __shared__ float psums[8];
    const int64_t inc  = (int64_t)(int)(512 * (unsigned)nblocks);
    const int64_t nn   = n;
    const unsigned w    = threadIdx.x / 64;
    const unsigned lane = threadIdx.x % 64;
    const unsigned q    = threadIdx.x % 128; // quad index within the chunk
    const unsigned j    = threadIdx.x / 128;
    float sum = 0;

    const int64_t base = (int64_t)blockIdx.x * 512 + (int64_t)q * 4 + (int64_t)j * inc;
    if(base + 4 <= nn)
    {
        const float* p = x + base;
        float a = p[0], b = p[1], c = p[2], d = p[3];
        sum = (a * a + b * b) + (c * c + d * d);
    }
    else
    {
        for(int e = 0; e < 4; e++)
        {
            int64_t tid = base + e;
            if(tid < nn)
            {
                float a = x[tid];
                sum += a * a;
            }
        }
    }

    sum = rocblas_wavefront_reduce<64>(sum);
    if(lane == 0)
        psums[w] = sum;
    __syncthreads();
    if(threadIdx.x == 0)
    {
        float t = 0;
        for(int i = 0; i < 8; i++)
            t += psums[i];
        workspace[blockIdx.x] = t;
    }
}
