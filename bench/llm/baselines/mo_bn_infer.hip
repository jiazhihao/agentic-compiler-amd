#include "miopen_common.h"

#ifndef BLK
#define BLK 256
#endif
#ifndef NPT
#define NPT 1
#endif

typedef float __attribute__((ext_vector_type(4))) f4;

extern "C" __global__ void __launch_bounds__(BLK)
    mo_bn_infer(const float* __restrict in,
                float* __restrict out,
                const float* __restrict estimatedMean,
                const float* __restrict estimatedVariance,
                const float* __restrict scale,
                const float* __restrict bias,
                double epsilon,
                unsigned int c,
                unsigned int hw,
                unsigned int batchSize,
                unsigned int cStride,
                unsigned int hwStride,
                unsigned int batchStride,
                float alpha,
                float beta)
{
    const unsigned int hw4 = (hw + 3u) >> 2;
    const unsigned int tid = blockIdx.x * BLK + threadIdx.x;
    const unsigned int ch  = tid / hw4;
    const unsigned int y   = tid - ch * hw4;
    if(ch >= c)
        return;
    const float m  = estimatedMean[ch];
    const float v  = estimatedVariance[ch];
    const float s  = scale[ch];
    const float b  = bias[ch];
    const float iv = __builtin_amdgcn_rsqf(__builtin_fabsf(v + static_cast<float>(epsilon)));
    const unsigned int base = ch * cStride + y * hwStride * 4u;
    unsigned int n = blockIdx.y * NPT;
    f4 x[NPT];
    unsigned int idx[NPT];
#pragma unroll
    for(unsigned int k = 0; k < NPT; ++k)
    {
        unsigned int nn = n + k < batchSize ? n + k : batchSize - 1u;
        idx[k] = nn * batchStride + base;
        x[k]   = *reinterpret_cast<const f4*>(in + idx[k]);
    }
#pragma unroll
    for(unsigned int k = 0; k < NPT; ++k)
    {
        f4 r = (x[k] - m) * iv;
        r    = s * r + b;
        *reinterpret_cast<f4*>(out + idx[k]) = r;
    }
}
