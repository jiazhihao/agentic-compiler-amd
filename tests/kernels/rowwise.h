// Shared by the rowwise kernels: one workgroup per row, each lane strides over the columns,
// then a tree reduction through LDS.
#pragma once
#include <hip/hip_runtime.h>

#define ROW_BLOCK 256

template <typename T, typename F>
__device__ inline T block_reduce(T* red, T mine, F op) {
    red[threadIdx.x] = mine;
    __syncthreads();
    for (int s = ROW_BLOCK / 2; s > 0; s >>= 1) {
        if (threadIdx.x < s) red[threadIdx.x] = op(red[threadIdx.x], red[threadIdx.x + s]);
        __syncthreads();
    }
    T r = red[0];
    __syncthreads();
    return r;
}
