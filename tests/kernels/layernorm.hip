// y[r, j] = (x[r, j] - mean) / sqrt(var + eps) * g[j] + b[j]
#include "rowwise.h"

extern "C" __global__ void layernorm(const float* x, const float* g, const float* b, float* y, float eps,
                                     int rows, int cols) {
    __shared__ float red[ROW_BLOCK];
    const float* row = x + (size_t)blockIdx.x * cols;
    float* out = y + (size_t)blockIdx.x * cols;
    auto add = [](float a, float c) { return a + c; };
    float s = 0.0f;
    for (int j = threadIdx.x; j < cols; j += ROW_BLOCK) s += row[j];
    float mean = block_reduce(red, s, add) / (float)cols;
    float v = 0.0f;
    for (int j = threadIdx.x; j < cols; j += ROW_BLOCK) v += (row[j] - mean) * (row[j] - mean);
    float scale = 1.0f / sqrtf(block_reduce(red, v, add) / (float)cols + eps);
    for (int j = threadIdx.x; j < cols; j += ROW_BLOCK) out[j] = (row[j] - mean) * scale * g[j] + b[j];
}
