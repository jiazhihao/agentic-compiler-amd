// Constructs agc's frontend refuses: each is reported with its source location, all at once.
#include <hip/hip_runtime.h>

extern "C" __global__ void refused(const float* x, float* y, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    float local[4] = {0.0f, 1.0f, 2.0f, 3.0f};
    switch (i & 3) {
        case 0: y[i] = x[i]; break;
        default: y[i] = local[i & 3]; break;
    }
    if (i == n) goto done;
    y[i] += 1.0f;
done:
    return;
}
