// y[r, j] = x[r, j] * rsqrt(mean_j(x[r, :]^2) + eps) * w[j]
#include "rowwise.h"

extern "C" __global__ void rmsnorm(const float* x, const float* w, float* y, float eps, int rows, int cols) {
    __shared__ float red[ROW_BLOCK];
    const float* row = x + (size_t)blockIdx.x * cols;
    float* out = y + (size_t)blockIdx.x * cols;
    float ss = 0.0f;
    for (int j = threadIdx.x; j < cols; j += ROW_BLOCK) ss += row[j] * row[j];
    ss = block_reduce(red, ss, [](float a, float b) { return a + b; });
    float scale = 1.0f / sqrtf(ss / (float)cols + eps);
    for (int j = threadIdx.x; j < cols; j += ROW_BLOCK) out[j] = row[j] * scale * w[j];
}
