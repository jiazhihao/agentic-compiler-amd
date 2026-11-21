// From MIOpen (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// ReduceSumFLOATACCUM, projects/miopen/src/kernels/MIOpenReduceSum.cpp, with block_reduce from
// block_reduce.hpp / warp_reduce.hpp (miopen_common.h).
// Build options of solver/prelu/backward_prelu_single_weight.cpp (phase 2): -DMIOPEN_USE_FP32=1
// -DREDUCE_SIZE=256 (LOCAL_SIZE_SW_REDUCE_BWD).
#include "miopen_common.h"

#define REDUCE_SIZE 256

extern "C" __global__ void mo_reduce_sum(const FLOAT_ACCUM* __restrict__ input,
                                         FLOAT_ACCUM* __restrict__ output,
                                         uint64_t N)
{
    uint64_t gid = blockIdx.x * blockDim.x + threadIdx.x;

    FLOAT_ACCUM val = gid < N ? input[gid] : 0.0f;
    val             = block_reduce<BinaryOp_t::Add, REDUCE_SIZE, ReduceThreadDim::X>(val);

    if(threadIdx.x == 0)
        output[blockIdx.x] = val;
}
