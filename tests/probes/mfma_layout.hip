// Placeholder so that the probe manifest has a HIP source; the probe kernels are written in mir
// (tests/test_gemm.py) and only the manifest's contract (arguments, launch, reference) is used.
#include <hip/hip_runtime.h>
extern "C" __global__ void mfma_layout(const unsigned short* a, const unsigned short* b, float* d) {}
