// C[M, N] = A[M, K] @ B[N, K]^T with OCP FP8 (E4M3) inputs and an f32 result (the linear-layer form:
// both operands are contiguous along K). One lane per output element; the decode is exact.
#include <hip/hip_runtime.h>

// OCP FP8 E4M3 (no infinities): 1 sign, 4 exponent (bias 7), 3 mantissa bits; exponent 0 is subnormal.
__device__ inline float e4m3_to_float(unsigned char v) {
    const int e = (v >> 3) & 15, f = v & 7;
    const float mag = e == 0 ? ldexpf((float)f, -9) : ldexpf((float)(8 + f), e - 10);
    return (v & 0x80) ? -mag : mag;
}

extern "C" __global__ void gemm_fp8(const unsigned char* A, const unsigned char* B, float* C, int M, int N, int K) {
    int n = blockIdx.x * blockDim.x + threadIdx.x;
    int m = blockIdx.y * blockDim.y + threadIdx.y;
    if (m >= M || n >= N) return;
    const unsigned char* a = A + (size_t)m * K;
    const unsigned char* b = B + (size_t)n * K;
    float acc = 0.0f;
    for (int k = 0; k < K; ++k) acc += e4m3_to_float(a[k]) * e4m3_to_float(b[k]);
    C[(size_t)m * N + n] = acc;
}
