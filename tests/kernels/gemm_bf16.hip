// C[M, N] = A[M, K] @ B[N, K]^T with bf16 inputs and an f32 result (the linear-layer form:
// both operands are contiguous along K). One lane per output element.
#include <hip/hip_runtime.h>

__device__ inline float bf16_to_float(unsigned short h) { return __builtin_bit_cast(float, (unsigned)h << 16); }

extern "C" __global__ void gemm_bf16(const unsigned short* A, const unsigned short* B, float* C, int M, int N, int K) {
    int n = blockIdx.x * blockDim.x + threadIdx.x;
    int m = blockIdx.y * blockDim.y + threadIdx.y;
    if (m >= M || n >= N) return;
    const unsigned short* a = A + (size_t)m * K;
    const unsigned short* b = B + (size_t)n * K;
    float acc = 0.0f;
    for (int k = 0; k < K; ++k) acc += bf16_to_float(a[k]) * bf16_to_float(b[k]);
    C[(size_t)m * N + n] = acc;
}
