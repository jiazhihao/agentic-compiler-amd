// y[i] = a * x[i] + y[i]
#include <hip/hip_runtime.h>

extern "C" __global__ void axpy(const float* x, float* y, float a, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = a * x[i] + y[i];
}
