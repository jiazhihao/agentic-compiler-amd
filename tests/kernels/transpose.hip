// y[j, i] = x[i, j]
#include <hip/hip_runtime.h>

extern "C" __global__ void transpose(const float* x, float* y, int rows, int cols) {
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    int i = blockIdx.y * blockDim.y + threadIdx.y;
    if (i < rows && j < cols) y[(size_t)j * rows + i] = x[(size_t)i * cols + j];
}
