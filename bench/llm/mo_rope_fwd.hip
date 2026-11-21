// From MIOpen (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// RoPEFwdContiguous + ropefwdcontiguous<INPUT_TYPE, OUTPUT_TYPE>, projects/miopen/src/kernels/MIOpenRoPE.cpp
// Build options of solver/rope/forward_rope.cpp for float: -DMIOPEN_USE_FP32=1 -DINPUT_TYPE=float
// -DOUTPUT_TYPE=float.
#include "miopen_common.h"

#define INPUT_TYPE float
#define OUTPUT_TYPE float

template <typename TI, typename TO>
__device__ void ropefwdcontiguous(const TI* __restrict__ x,
                                  const TI* __restrict__ cos,
                                  const TI* __restrict__ sin,
                                  TO* __restrict__ y,
                                  uint64_t output_numel,
                                  uint64_t rotary_numel)
{
    const uint64_t gid = threadIdx.x + blockIdx.x * blockDim.x;
    if(gid >= output_numel)
        return;

    FLOAT_ACCUM input = CVT_FLOAT2ACCUM(x[gid]);

    uint64_t freqs_id = gid % rotary_numel;

    FLOAT_ACCUM input_rotate_half =
        (gid % 2 == 0) ? -CVT_FLOAT2ACCUM(x[(gid + 1)]) : CVT_FLOAT2ACCUM(x[gid - 1]);

    FLOAT_ACCUM cos_val = CVT_FLOAT2ACCUM(cos[freqs_id]);
    FLOAT_ACCUM sin_val = CVT_FLOAT2ACCUM(sin[freqs_id]);

    FLOAT_ACCUM val = (input * cos_val) + (input_rotate_half * sin_val);

    y[gid] = CVT_ACCUM2FLOAT(val);
}

extern "C" __global__ void mo_rope_fwd(const INPUT_TYPE* __restrict__ x,
                                       const INPUT_TYPE* __restrict__ cos,
                                       const INPUT_TYPE* __restrict__ sin,
                                       OUTPUT_TYPE* __restrict__ y,
                                       uint64_t output_numel,
                                       uint64_t rotary_numel)
{
    // instantiate the kernel
    ropefwdcontiguous<INPUT_TYPE, OUTPUT_TYPE>(x, cos, sin, y, output_numel, rotary_numel);
}
