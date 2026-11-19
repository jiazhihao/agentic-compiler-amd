// out[r] = argmax_j x[r, j] (first maximum)
#include "rowwise.h"

struct Best { float v; int j; };

extern "C" __global__ void row_argmax(const float* x, int* out, int rows, int cols) {
    __shared__ Best red[ROW_BLOCK];
    const float* row = x + (size_t)blockIdx.x * cols;
    Best b{-INFINITY, 0x7fffffff};
    for (int j = threadIdx.x; j < cols; j += ROW_BLOCK)
        if (row[j] > b.v) b = Best{row[j], j};
    b = block_reduce(red, b, [](Best a, Best c) { return (c.v > a.v || (c.v == a.v && c.j < a.j)) ? c : a; });
    if (threadIdx.x == 0) out[blockIdx.x] = b.j;
}
