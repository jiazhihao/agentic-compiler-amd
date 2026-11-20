#include <hip/hip_runtime.h>
#include <cstdint>
#ifndef EPL
#define EPL 4
#endif
#define LPO (256 / EPL)

extern "C" __global__ void mo_reduce_sum(const float* __restrict__ input,
                                         float* __restrict__ output,
                                         uint64_t N)
{
    uint64_t g    = (uint64_t)blockIdx.x * blockDim.x + threadIdx.x;
    uint64_t o    = g / LPO;
    uint32_t j    = (uint32_t)(g % LPO);
    uint64_t base = o * 256 + (uint64_t)j * EPL;
    float val = 0.0f;
    if(base + EPL <= N)
    {
        const float* p = input + base;
        float s[EPL];
        for(int i = 0; i < EPL; ++i) s[i] = p[i];
        for(int w = EPL; w > 1; w >>= 1)
            for(int i = 0; i < w / 2; ++i) s[i] = s[2 * i] + s[2 * i + 1];
        val = s[0];
    }
    else
    {
        for(int i = 0; i < EPL; ++i)
            if(base + i < N) val += input[base + i];
    }
    for(int d = LPO / 2; d >= 1; d >>= 1)
        val += __shfl_down(val, d);
    if(j == 0 && o * 256 < N)
        output[o] = val;
}
