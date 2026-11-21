// From MIOpen (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// T5LayernormFwdContiguous + t5layernormfwdcontiguous<INPUT_TYPE, OUTPUT_TYPE>,
// projects/miopen/src/kernels/MIOpenT5LayerNorm.cpp
// Build options of solver/layernorm/forward_t5layernorm.cpp for float: -DMIOPEN_USE_FP32=1
// -DINPUT_TYPE=float -DOUTPUT_TYPE=float -DLOCAL_SIZE=256 -DMIOPEN_ELEMENTWISE_AFFINE_T5=4
// -DMIOPEN_WEIGHT_BIAS_T5=5.
#include "miopen_common.h"

#define INPUT_TYPE float
#define OUTPUT_TYPE float
#define LOCAL_SIZE 256
#define MIOPEN_ELEMENTWISE_AFFINE_T5 4
#define MIOPEN_WEIGHT_BIAS_T5 5

template <typename TI, typename TO>
__device__ void t5layernormfwdcontiguous(const TI* __restrict__ x,
                                         const TI* __restrict__ weight,
                                         TO* __restrict__ y,
                                         TO* __restrict__ rstd,
                                         float eps,
                                         uint64_t inner_size,
                                         int32_t mode)
{
    const uint64_t gid = blockIdx.x;
    const uint64_t lid = threadIdx.x;

    FLOAT_ACCUM pvar = static_cast<FLOAT_ACCUM>(0);
    __shared__ FLOAT_ACCUM ltmp[LOCAL_SIZE];

    // reduce sum
    for(uint64_t i = lid; i < inner_size; i += LOCAL_SIZE)
    {
        size_t x_idx = gid * inner_size + i;

        FLOAT_ACCUM tmp = CVT_FLOAT2ACCUM(x[x_idx]);
        pvar += tmp * tmp;
    }

    ltmp[lid] = pvar;
    __syncthreads();
    for(uint32_t i = LOCAL_SIZE >> 1; i > 0; i >>= 1)
    {
        if(lid < i)
        {
            ltmp[lid] += ltmp[lid + i];
        }
        __syncthreads();
    }
    pvar              = ltmp[0] / inner_size;
    FLOAT_ACCUM prstd = rsqrt(pvar + FLOAT_ACCUM(eps));

    if(lid == 0)
    {
        if(rstd)
            rstd[gid] = CVT_ACCUM2FLOAT(prstd);
    }

    // forward calculation
    for(uint64_t i = lid; i < inner_size; i += LOCAL_SIZE)
    {
        size_t idx = gid * inner_size + i;

        FLOAT_ACCUM pweight;
        pweight = (mode == MIOPEN_ELEMENTWISE_AFFINE_T5) ? CVT_FP32_2ACCUM(1.0f)
                                                         : CVT_FLOAT2ACCUM(weight[i]);

        FLOAT_ACCUM val = (CVT_FLOAT2ACCUM(x[idx])) * prstd * pweight;
        y[idx]          = CVT_ACCUM2FLOAT(val);
    }
}

extern "C" __global__ void mo_t5_layernorm(const INPUT_TYPE* __restrict__ x,
                                           const INPUT_TYPE* __restrict__ weight,
                                           OUTPUT_TYPE* __restrict__ y,
                                           OUTPUT_TYPE* __restrict__ rstd,
                                           float eps,
                                           uint64_t inner_size,
                                           int32_t mode)
{
    // instantiate the kernel
    t5layernormfwdcontiguous<INPUT_TYPE, OUTPUT_TYPE>(x, weight, y, rstd, eps, inner_size, mode);
}
