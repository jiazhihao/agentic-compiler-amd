// y[i] = sum_j A[i, j] * x[j]
#include <hip/hip_runtime.h>

extern "C" __global__ void matvec(const float* A, const float* x, float* y, int rows, int cols) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= rows) return;
    const float* row = A + (size_t)i * cols;
    float acc = 0.0f;
    for (int j = 0; j < cols; ++j) acc += row[j] * x[j];
    y[i] = acc;
}
