// y[i] = bf16(x[i]), round to nearest even (finite inputs)
#include <hip/hip_runtime.h>

extern "C" __global__ void cast_bf16(const float* x, unsigned short* y, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        unsigned u = __builtin_bit_cast(unsigned, x[i]);
        u += 0x7fffu + ((u >> 16) & 1u);
        y[i] = (unsigned short)(u >> 16);
    }
}
