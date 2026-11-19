// Not a corpus kernel: exercises amdclang's MFMA code generation so that the hazard rules for
// MFMA (results read by MFMA / VALU / memory, accumulator chains) are checked against the
// compiler's own s_nop placement.
#include <hip/hip_runtime.h>

typedef float v4f __attribute__((ext_vector_type(4)));
typedef float v16f __attribute__((ext_vector_type(16)));
typedef __bf16 v8bf __attribute__((ext_vector_type(8)));
typedef _Float16 v8h __attribute__((ext_vector_type(8)));
typedef _Float16 v4h __attribute__((ext_vector_type(4)));

extern "C" __global__ void mfma_chain(const v8bf* a, const v8bf* b, float* out, int n) {
    int i = threadIdx.x;
    v16f acc = {0};
    for (int k = 0; k < n; ++k)
        acc = __builtin_amdgcn_mfma_f32_32x32x16_bf16(a[i + 64 * k], b[i + 64 * k], acc, 0, 0, 0);
    for (int j = 0; j < 16; ++j) out[i * 16 + j] = acc[j];
}

extern "C" __global__ void mfma_read_now(const v8bf* a, const v8bf* b, float* out) {
    int i = threadIdx.x;
    v4f z = {0};
    v4f r = __builtin_amdgcn_mfma_f32_16x16x32_bf16(a[i], b[i], z, 0, 0, 0);
    out[i] = r[0] + r[1] * r[2] - r[3];                 // VALU reads the result at once
}

extern "C" __global__ void mfma_feed(const v8h* a, const v8h* b, const v4h* c, float* out) {
    int i = threadIdx.x;
    v4f z = {0};
    v4f r = __builtin_amdgcn_mfma_f32_16x16x32_f16(a[i], b[i], z, 0, 0, 0);
    v4h h = {(_Float16)r[0], (_Float16)r[1], (_Float16)r[2], (_Float16)r[3]};
    v4f s = __builtin_amdgcn_mfma_f32_16x16x16f16(h, c[i], r, 0, 0, 0);     // result feeds A and C of another MFMA
    v4f t = __builtin_amdgcn_mfma_f32_4x4x4f16(c[i], h, s, 0, 0, 0);
    v4f u = __builtin_amdgcn_mfma_f32_4x4x4f16(c[i], h, t, 0, 0, 0);       // 2-pass accumulator chain
    for (int j = 0; j < 4; ++j) out[i * 4 + j] = u[j] + s[j];
}

extern "C" __global__ void mfma_sgemm(const float* a, const float* b, float* out) {
    int i = threadIdx.x;
    v16f acc = {0};
    acc = __builtin_amdgcn_mfma_f32_32x32x2f32(a[i], b[i], acc, 0, 0, 0);
    acc = __builtin_amdgcn_mfma_f32_32x32x2f32(a[i + 64], b[i + 64], acc, 0, 0, 0);
    v4f q = {acc[0], acc[1], acc[2], acc[3]};
    q = __builtin_amdgcn_mfma_f32_16x16x4f32(acc[4], b[i], q, 0, 0, 0);
    for (int j = 0; j < 4; ++j) out[i * 4 + j] = q[j];
}
