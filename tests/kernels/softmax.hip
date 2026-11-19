// y[r, :] = softmax(x[r, :])
#include "rowwise.h"

extern "C" __global__ void softmax(const float* x, float* y, int rows, int cols) {
    __shared__ float red[ROW_BLOCK];
    const float* row = x + (size_t)blockIdx.x * cols;
    float* out = y + (size_t)blockIdx.x * cols;
    float m = -INFINITY;
    for (int j = threadIdx.x; j < cols; j += ROW_BLOCK) m = fmaxf(m, row[j]);
    m = block_reduce(red, m, [](float a, float b) { return fmaxf(a, b); });
    float s = 0.0f;
    for (int j = threadIdx.x; j < cols; j += ROW_BLOCK) s += expf(row[j] - m);
    s = block_reduce(red, s, [](float a, float b) { return a + b; });
    float inv = 1.0f / s;
    for (int j = threadIdx.x; j < cols; j += ROW_BLOCK) out[j] = expf(row[j] - m) * inv;
}
