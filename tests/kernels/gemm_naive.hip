// C[M, N] = A[M, K] @ B[K, N], one lane per output element
#include <hip/hip_runtime.h>

extern "C" __global__ void gemm_naive(const float* A, const float* B, float* C, int M, int N, int K) {
    int n = blockIdx.x * blockDim.x + threadIdx.x;
    int m = blockIdx.y * blockDim.y + threadIdx.y;
    if (m >= M || n >= N) return;
    float acc = 0.0f;
    for (int k = 0; k < K; ++k) acc += A[(size_t)m * K + k] * B[(size_t)k * N + n];
    C[(size_t)m * N + n] = acc;
}
