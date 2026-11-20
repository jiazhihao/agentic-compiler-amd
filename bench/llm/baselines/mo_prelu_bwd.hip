#include "miopen_common.h"

#ifndef EPT
#define EPT 4
#endif
#ifndef BLK
#define BLK 256
#endif

typedef float vecf __attribute__((ext_vector_type(EPT), aligned(4)));

extern "C" __global__ void mo_prelu_bwd(const float* __restrict__ input,
                                        const float* __restrict__ weight,
                                        const float* __restrict__ output_grad,
                                        float* __restrict__ input_grad,
                                        float* __restrict__ weight_grad_collector,
                                        uint64_t N)
{
    uint64_t base = ((uint64_t)blockIdx.x * BLK + threadIdx.x) * EPT;
    if(base >= N)
        return;
    if(base + EPT <= N)
    {
        vecf x = *(const vecf*)(input + base);
        vecf g = *(const vecf*)(output_grad + base);
        if(input_grad != nullptr)
        {
            float w = weight[0];
            vecf r;
            for(int i = 0; i < EPT; ++i)
                r[i] = x[i] > 0 ? g[i] : w * g[i];
            *(vecf*)(input_grad + base) = r;
        }
        if(weight_grad_collector != nullptr)
        {
            vecf r;
            for(int i = 0; i < EPT; ++i)
                r[i] = x[i] > 0 ? 0.0f : x[i] * g[i];
            *(vecf*)(weight_grad_collector + base) = r;
        }
        return;
    }
    for(uint64_t gid = base; gid < N; ++gid)
    {
        float input_v = input[gid];
        float grad_v  = output_grad[gid];
        if(input_grad != nullptr)
        {
            float weight_v = weight[0];
            input_grad[gid] = input_v > 0 ? grad_v : weight_v * grad_v;
        }
        if(weight_grad_collector != nullptr)
            weight_grad_collector[gid] = input_v > 0 ? 0 : input_v * grad_v;
    }
}
