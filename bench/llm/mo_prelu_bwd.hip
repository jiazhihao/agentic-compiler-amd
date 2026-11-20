// From MIOpen (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// PReLUSWBackward + PReLUBackward<INPUT_TYPE, OUTPUT_TYPE, VIEW_DIMS, SingleWeight = true>,
// projects/miopen/src/kernels/MIOpenPReLU.cpp
// Build options of solver/prelu/backward_prelu_single_weight.cpp (phase 1) for float: -DMIOPEN_USE_FP32=1
// -DINPUT_TYPE=float -DOUTPUT_TYPE=float -DVIEW_DIMS=5.
// Contiguous tensors: the four tensor_view_t arguments are removed. For a contiguous view
// tensor_view_t::get_tensor_view_idx(tensor_layout_t(tv, gid)) == gid, so the index decomposition
// (tensor_layout_t) and recomposition are replaced by gid; the single weight is weight[0].
#include "miopen_common.h"

#define INPUT_TYPE float
#define OUTPUT_TYPE float

template <typename TI, typename TO, bool SingleWeight>
__device__ void PReLUBackward(const TI* __restrict__ input,
                              const TI* __restrict__ weight,
                              const TO* __restrict__ output_grad,
                              TI* __restrict__ input_grad,
                              FLOAT_ACCUM* __restrict__ weight_grad_collector,
                              uint64_t N)
{
    uint64_t gid = blockIdx.x * blockDim.x + threadIdx.x;
    if(gid >= N)
        return;

    FLOAT_ACCUM input_v = CVT_FLOAT2ACCUM(input[gid]);
    FLOAT_ACCUM grad_v  = CVT_FLOAT2ACCUM(output_grad[gid]);

    if(input_grad != nullptr)
    {
        FLOAT_ACCUM weight_v     = CVT_FLOAT2ACCUM(weight[0]);
        FLOAT_ACCUM input_grad_v = input_v > 0 ? grad_v : weight_v * grad_v;
        input_grad[gid]          = CVT_ACCUM2FLOAT(input_grad_v);
    }
    if(weight_grad_collector != nullptr)
    {
        weight_grad_collector[gid] = input_v > 0 ? 0 : input_v * grad_v;
    }
}

extern "C" __global__ void mo_prelu_bwd(const INPUT_TYPE* __restrict__ input,
                                        const INPUT_TYPE* __restrict__ weight,
                                        const OUTPUT_TYPE* __restrict__ output_grad,
                                        INPUT_TYPE* __restrict__ input_grad,
                                        FLOAT_ACCUM* __restrict__ weight_grad_collector,
                                        uint64_t N)
{
    // instantiate the kernel
    PReLUBackward<INPUT_TYPE, OUTPUT_TYPE, true>(
        input, weight, output_grad, input_grad, weight_grad_collector, N);
}
