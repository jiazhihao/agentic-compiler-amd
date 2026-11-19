// Times hipBLASLt on C[M,N] = A[M,K] @ B[N,K]^T (row-major, the layout of the agc corpus kernel
// gemm_bf16), with the sampling of the agc timing protocol: per sample an optional cache flush, hipEvents
// around one call, medians. Prints one JSON object.
//
//   hipblaslt_bench M N K in_type out_type samples flush      (types: bf16 | f16 | f32)
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#include <hip/hip_runtime.h>
#include <hipblaslt/hipblaslt.h>

#define CHECK(x) do { auto s_ = (x); if (s_ != 0) { printf("{\"ok\": false, \"error\": \"%s failed: %d\"}\n", #x, (int)s_); return 1; } } while (0)

static hipDataType dtype(const std::string& s) {
    if (s == "bf16") return HIP_R_16BF;
    if (s == "f16") return HIP_R_16F;
    return HIP_R_32F;
}
static size_t bytes(const std::string& s) { return s == "f32" ? 4 : 2; }

int main(int argc, char** argv) {
    if (argc < 8) { printf("{\"ok\": false, \"error\": \"usage\"}\n"); return 2; }
    int64_t M = atoll(argv[1]), N = atoll(argv[2]), K = atoll(argv[3]);
    std::string tin = argv[4], tout = argv[5];
    int samples = atoi(argv[6]);
    bool flush = atoi(argv[7]) != 0;
    void *a, *b, *c, *fl = nullptr, *ws;
    const size_t flush_bytes = 576u << 20, ws_bytes = 64u << 20;
    CHECK(hipMalloc(&a, M * K * bytes(tin)));
    CHECK(hipMalloc(&b, N * K * bytes(tin)));
    CHECK(hipMalloc(&c, M * N * bytes(tout)));
    CHECK(hipMalloc(&ws, ws_bytes));
    if (flush) CHECK(hipMalloc(&fl, flush_bytes));
    {   // small values with an exact representation in every type
        std::vector<unsigned short> h(std::max(M, N) * K);
        std::vector<float> f(std::max(M, N) * K);
        for (size_t i = 0; i < h.size(); ++i) {
            float v = (float)((int)((i * 2654435761u) >> 28) - 8) * 0.125f;
            f[i] = v;
            unsigned u; memcpy(&u, &v, 4);
            h[i] = (unsigned short)(u >> 16);            // bf16 bits; for f16 the values are arbitrary but finite
        }
        const void* src = tin == "f32" ? (const void*)f.data() : (const void*)h.data();
        CHECK(hipMemcpy(a, src, M * K * bytes(tin), hipMemcpyHostToDevice));
        CHECK(hipMemcpy(b, src, N * K * bytes(tin), hipMemcpyHostToDevice));
    }
    hipblasLtHandle_t handle;
    CHECK(hipblasLtCreate(&handle));
    // Row-major X[r, c] is the column-major matrix X^T (c x r). C^T (N x M) = B'^T @ A' with
    // B' = B^T (K x N) and A' = A^T (K x M).
    hipblasLtMatrixLayout_t la, lb, lc;
    CHECK(hipblasLtMatrixLayoutCreate(&la, dtype(tin), K, N, K));      // first operand: B'
    CHECK(hipblasLtMatrixLayoutCreate(&lb, dtype(tin), K, M, K));      // second operand: A'
    CHECK(hipblasLtMatrixLayoutCreate(&lc, dtype(tout), N, M, N));
    hipblasLtMatmulDesc_t desc;
    CHECK(hipblasLtMatmulDescCreate(&desc, HIPBLAS_COMPUTE_32F, HIP_R_32F));
    hipblasOperation_t t = HIPBLAS_OP_T, nt = HIPBLAS_OP_N;
    CHECK(hipblasLtMatmulDescSetAttribute(desc, HIPBLASLT_MATMUL_DESC_TRANSA, &t, sizeof(int32_t)));
    CHECK(hipblasLtMatmulDescSetAttribute(desc, HIPBLASLT_MATMUL_DESC_TRANSB, &nt, sizeof(int32_t)));
    hipblasLtMatmulPreference_t pref;
    CHECK(hipblasLtMatmulPreferenceCreate(&pref));
    uint64_t wsb = ws_bytes;
    CHECK(hipblasLtMatmulPreferenceSetAttribute(pref, HIPBLASLT_MATMUL_PREF_MAX_WORKSPACE_BYTES, &wsb, sizeof(wsb)));
    hipblasLtMatmulHeuristicResult_t heur[1];
    int found = 0;
    CHECK(hipblasLtMatmulAlgoGetHeuristic(handle, desc, la, lb, lc, lc, pref, 1, heur, &found));
    if (found == 0) { printf("{\"ok\": false, \"error\": \"no hipBLASLt solution for %s -> %s\"}\n", tin.c_str(), tout.c_str()); return 1; }
    float alpha = 1.0f, beta = 0.0f;
    hipStream_t stream;
    CHECK(hipStreamCreate(&stream));
    hipEvent_t e0, e1;
    CHECK(hipEventCreate(&e0));
    CHECK(hipEventCreate(&e1));
    std::vector<float> ms;
    for (int i = 0; i < samples + 10; ++i) {
        if (flush) CHECK(hipMemsetAsync(fl, i & 0xff, flush_bytes, stream));
        CHECK(hipStreamSynchronize(stream));
        CHECK(hipEventRecord(e0, stream));
        CHECK(hipblasLtMatmul(handle, desc, &alpha, b, la, a, lb, &beta, c, lc, c, lc, &heur[0].algo, ws, ws_bytes, stream));
        CHECK(hipEventRecord(e1, stream));
        CHECK(hipEventSynchronize(e1));
        float t_ms = 0;
        CHECK(hipEventElapsedTime(&t_ms, e0, e1));
        if (i >= 10) ms.push_back(t_ms);
    }
    std::sort(ms.begin(), ms.end());
    std::vector<float> out(4);
    CHECK(hipMemcpy(out.data(), c, 4 * bytes(tout) > 16 ? 16 : 4 * bytes(tout), hipMemcpyDeviceToHost));
    printf("{\"ok\": true, \"library\": \"hipBLASLt\", \"M\": %lld, \"N\": %lld, \"K\": %lld, \"in\": \"%s\", \"out\": \"%s\", "
           "\"samples\": %d, \"flush\": %s, \"median_ms\": %.6f, \"min_ms\": %.6f, \"p90_ms\": %.6f}\n",
           (long long)M, (long long)N, (long long)K, tin.c_str(), tout.c_str(), samples, flush ? "true" : "false",
           ms[ms.size() / 2], ms.front(), ms[ms.size() * 9 / 10]);
    return 0;
}
