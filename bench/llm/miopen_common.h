// Device helpers copied from MIOpen (ROCm/rocm-libraries @ 207bc1a58e95, MIT, see LICENSES.md),
// for the FP32 build (-DMIOPEN_USE_FP32=1: FLOAT = FLOAT_ACCUM = float). Sources:
//   projects/miopen/src/kernels/float_types.h    (the FP32 branch of the type / conversion macros)
//   projects/miopen/src/kernels/warp_reduce.hpp  (BinaryOp_t, BinaryFunc, warp_reduce)
//   projects/miopen/src/kernels/block_reduce.hpp (ReduceThreadDim, block_reduce_warp, block_reduce)
#pragma once
#include <hip/hip_runtime.h>
#include <cstddef>
#include <cstdint>

// float_types.h, MIOPEN_USE_FP32 == 1
#define FLOAT float
#define FLOAT_ACCUM float
#define CVT_FLOAT2ACCUM(x) (static_cast<FLOAT_ACCUM>(x))
#define CVT_ACCUM2FLOAT(x) (static_cast<FLOAT>(x))
#define CVT_INTEGRAL2ACCUM(x) (static_cast<FLOAT_ACCUM>(x))
#define CVT_FP32_2FLOAT(x) (CVT_ACCUM2FLOAT(x))
#define CVT_FP32_2ACCUM(x) (x)
#define CVT_FLOAT2FP32(x) (CVT_FLOAT2ACCUM(x))
#define CVT_ACCUM2FP32(x) (x)

// warp_reduce.hpp
enum class BinaryOp_t
{
    Add,
};

template <BinaryOp_t Op, typename T>
struct BinaryFunc;

template <typename T>
struct BinaryFunc<BinaryOp_t::Add, T>
{
    constexpr void exec(T& a, const T& b) { a += b; }
};

template <BinaryOp_t Op>
__device__ FLOAT_ACCUM warp_reduce(FLOAT_ACCUM val)
{
    for(auto d = warpSize / 2; d >= 1; d >>= 1)
        BinaryFunc<Op, FLOAT_ACCUM>{}.exec(val, __shfl_down(val, d));
    return val;
}

// block_reduce.hpp
enum class ReduceThreadDim : int32_t
{
    X = 1 << 0,
    Y = 1 << 1,
    Z = 1 << 2,
};

template <uint32_t WARP_SIZE, BinaryOp_t Op, uint64_t reduce_size, ReduceThreadDim thread_dim>
__device__ FLOAT_ACCUM block_reduce_warp(FLOAT_ACCUM val)
{
    // non-zero size
    static __shared__ FLOAT_ACCUM shared[(reduce_size + WARP_SIZE - 1) / WARP_SIZE];
    uint64_t tid = 0;
    if(static_cast<int32_t>(thread_dim) & static_cast<int32_t>(ReduceThreadDim::X))
        tid += threadIdx.x;
    if(static_cast<int32_t>(thread_dim) & static_cast<int32_t>(ReduceThreadDim::Y))
        tid = tid * blockDim.y + threadIdx.y;
    if(static_cast<int32_t>(thread_dim) & static_cast<int32_t>(ReduceThreadDim::Z))
        tid = tid * blockDim.z + threadIdx.z;
    const uint64_t lane = tid % WARP_SIZE;
    const uint64_t wid  = tid / WARP_SIZE;

    val = warp_reduce<Op>(val);
    if(lane == 0)
        shared[wid] = val;
    __syncthreads();

    val = tid < reduce_size / WARP_SIZE ? shared[lane] : 0;
    if(wid == 0)
        val = warp_reduce<Op>(val);

    return val;
}

template <BinaryOp_t Op, uint64_t reduce_size, ReduceThreadDim thread_dim>
__device__ FLOAT_ACCUM block_reduce(FLOAT_ACCUM val)
{
    if(reduce_size == warpSize)
        return warp_reduce<Op>(val);

    if(warpSize == 32)
    {
        return block_reduce_warp<32, Op, reduce_size, thread_dim>(val);
    }
    else
    {
        return block_reduce_warp<64, Op, reduce_size, thread_dim>(val);
    }
}
