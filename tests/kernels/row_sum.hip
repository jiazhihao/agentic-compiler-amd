// out[r] = sum_j x[r, j]
#include "rowwise.h"

extern "C" __global__ void row_sum(const float* x, float* out, int rows, int cols) {
    __shared__ float red[ROW_BLOCK];
    const float* row = x + (size_t)blockIdx.x * cols;
    float acc = 0.0f;
    for (int j = threadIdx.x; j < cols; j += ROW_BLOCK) acc += row[j];
    float s = block_reduce(red, acc, [](float a, float b) { return a + b; });
    if (threadIdx.x == 0) out[blockIdx.x] = s;
}
