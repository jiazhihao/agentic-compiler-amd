// Control flow for agc's own lowering (roadmap M12): break, continue, do-while, a return inside a
// loop of an inlined function. One thread per row (or per element); every loop here ends at a
// different iteration in each thread.
#include <hip/hip_runtime.h>

// out[i] = the first column j with x[i, j] < t, or -1
extern "C" __global__ void first_below(const float* x, int* out, float t, int rows, int cols) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= rows) return;
    const float* row = x + (size_t)i * cols;
    int found = -1;
    for (int j = 0; j < cols; ++j) {
        if (row[j] < t) {
            found = j;
            break;
        }
    }
    out[i] = found;
}

// out[i] = the sum of the positive entries of row i, in column order
extern "C" __global__ void sum_positive(const float* x, float* out, int rows, int cols) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= rows) return;
    float acc = 0.0f;
    for (int j = 0; j < cols; ++j) {
        float v = x[(size_t)i * cols + j];
        if (!(v > 0.0f)) continue;
        acc += v;
    }
    out[i] = acc;
}

// out[i] = how many times |x[i]| is halved until it is below 1 (at least once, at most 40 times)
extern "C" __global__ void halvings(const float* x, int* out, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    float v = x[i];
    if (v < 0.0f) v = -v;
    int k = 0;
    do {
        v *= 0.5f;
        ++k;
    } while (v >= 1.0f && k < 40);
    out[i] = k;
}

static __device__ __forceinline__ int last_at_least(const float* p, int n, float key) {
    for (int j = n - 1; j >= 0; --j)
        if (p[j] >= key) return j;
    return -1;
}

// out[i] = the last column j with x[i, j] >= t, or -1 (a return from inside a loop that counts down)
extern "C" __global__ void last_above(const float* x, int* out, float t, int rows, int cols) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < rows) out[i] = last_at_least(x + (size_t)i * cols, cols, t);
}

// Integer division and remainder: by a variable, by constants, signed and unsigned, 32 and 64 bits
// (the machine has no integer divide). q[i] and r[i] mix the results so that each one is checked.
extern "C" __global__ void divmod(const int* a, const int* b, int* q, int* r, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    int x = a[i], y = b[i];
    unsigned ux = (unsigned)x, uy = (unsigned)y;
    size_t wx = ux, wy = uy;                       // 64-bit operands that are 32-bit values extended
    q[i] = x / y + x / 7 - x / 16 + (int)(ux / uy) + (int)(ux / 641u) + (int)(wx / wy);
    r[i] = x % y - x % 13 + x % 8 + (int)(ux % uy) + (int)(ux % 10u) + (int)(wx % 1000u);
}
