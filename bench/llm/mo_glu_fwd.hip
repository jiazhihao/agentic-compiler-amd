// From MIOpen (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// GLUFwdContiguousDim0 + GLUFwdContiguousKernel<IO_TYPE> + sigmoid, projects/miopen/src/kernels/MIOpenGLU.cpp
// Build options of solver/glu/forward_glu.cpp for float: -DMIOPEN_USE_FP32=1 -DIO_TYPE=float.
#include "miopen_common.h"

#define IO_TYPE float

__device__ FLOAT_ACCUM sigmoid(FLOAT_ACCUM x) { return 1.0f / (1.0f + exp(-x)); }

template <typename TIO>
__device__ void GLUFwdContiguousKernel(const TIO* input, TIO* output, uint64_t N)
{
    const TIO* inputFirstHalf  = input;
    const TIO* inputSecondHalf = input + N;
    const size_t gid           = blockIdx.x * blockDim.x + threadIdx.x;
    if(gid >= N)
        return;

    FLOAT_ACCUM val1 = CVT_FLOAT2ACCUM(inputFirstHalf[gid]);
    FLOAT_ACCUM val2 = sigmoid(CVT_FLOAT2ACCUM(inputSecondHalf[gid]));
    FLOAT_ACCUM val  = val1 * val2;
    output[gid]      = CVT_ACCUM2FLOAT(val);
}

extern "C" __global__ void mo_glu_fwd(const IO_TYPE* input, IO_TYPE* output, uint64_t N)
{
    GLUFwdContiguousKernel<IO_TYPE>(input, output, N);
}
