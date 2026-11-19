// C[M, N] = A[M, K] @ B[K, N], 16x16 tiles of A and B staged through LDS
#include <hip/hip_runtime.h>

#define T 16

extern "C" __global__ void gemm_tiled(const float* A, const float* B, float* C, int M, int N, int K) {
    __shared__ float As[T][T];
    __shared__ float Bs[T][T];
    int tx = threadIdx.x, ty = threadIdx.y;
    int n = blockIdx.x * T + tx;
    int m = blockIdx.y * T + ty;
    float acc = 0.0f;
    for (int k0 = 0; k0 < K; k0 += T) {
        As[ty][tx] = (m < M && k0 + tx < K) ? A[(size_t)m * K + k0 + tx] : 0.0f;
        Bs[ty][tx] = (k0 + ty < K && n < N) ? B[(size_t)(k0 + ty) * N + n] : 0.0f;
        __syncthreads();
        for (int k = 0; k < T; ++k) acc += As[ty][k] * Bs[k][tx];
        __syncthreads();
    }
    if (m < M && n < N) C[(size_t)m * N + n] = acc;
}
