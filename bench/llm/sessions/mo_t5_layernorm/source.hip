#include "miopen_common.h"

#ifndef BLK
#define BLK 64
#endif
#ifndef NC
#define NC 4
#endif
typedef float v4f __attribute__((ext_vector_type(4), aligned(4)));

extern "C" __global__ void mo_t5_layernorm(const float* __restrict__ x,
                                           const float* __restrict__ weight,
                                           float* __restrict__ y,
                                           float* __restrict__ rstd,
                                           float eps,
                                           uint64_t inner_size,
                                           int32_t mode)
{
    const uint64_t gid = blockIdx.x;
    const uint32_t lid = threadIdx.x;
    const uint64_t D = inner_size;
    const float* xr = x + gid * D;
    float* yr = y + gid * D;
    const uint64_t nfull = D >> 2;
    __shared__ float ltmp[BLK];

    v4f c[NC];
    float pvar = 0.0f;
    for(int k = 0; k < NC; ++k)
    {
        uint64_t ci = (uint64_t)lid + (uint64_t)BLK * k;
        if(ci < nfull)
        {
            v4f t = *(const v4f*)(xr + 4 * ci);
            c[k] = t;
            pvar += t.x * t.x + t.y * t.y + t.z * t.z + t.w * t.w;
        }
        else
        {
            c[k] = (v4f)(0.0f);
        }
    }
    for(uint64_t ci = (uint64_t)lid + (uint64_t)BLK * NC; ci < nfull; ci += BLK)
    {
        v4f t = *(const v4f*)(xr + 4 * ci);
        pvar += t.x * t.x + t.y * t.y + t.z * t.z + t.w * t.w;
    }
    const uint64_t ti = nfull * 4 + lid;
    float tailv = 0.0f;
    if(lid < 3 && ti < D)
    {
        tailv = xr[ti];
        pvar += tailv * tailv;
    }

    ltmp[lid] = pvar;
#if BLK > 64
    __syncthreads();
#endif
    for(uint32_t i = BLK >> 1; i > 0; i >>= 1)
    {
        if(lid < i)
        {
            ltmp[lid] += ltmp[lid + i];
        }
#if BLK > 64
        __syncthreads();
#endif
    }
    pvar = ltmp[0] / inner_size;
    float prstd = rsqrt(pvar + eps);

    if(lid == 0)
    {
        if(rstd)
            rstd[gid] = prstd;
    }

    const bool affine_one = (mode == 4);
    for(int k = 0; k < NC; ++k)
    {
        uint64_t ci = (uint64_t)lid + (uint64_t)BLK * k;
        if(ci < nfull)
        {
            v4f w = affine_one ? (v4f)(1.0f) : *(const v4f*)(weight + 4 * ci);
            *(v4f*)(yr + 4 * ci) = c[k] * prstd * w;
        }
    }
    for(uint64_t ci = (uint64_t)lid + (uint64_t)BLK * NC; ci < nfull; ci += BLK)
    {
        v4f t = *(const v4f*)(xr + 4 * ci);
        v4f w = affine_one ? (v4f)(1.0f) : *(const v4f*)(weight + 4 * ci);
        *(v4f*)(yr + 4 * ci) = t * prstd * w;
    }
    if(lid < 3 && ti < D)
    {
        float w = affine_one ? 1.0f : weight[ti];
        yr[ti] = tailv * prstd * w;
    }
}
