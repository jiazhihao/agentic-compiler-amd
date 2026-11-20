// From rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// rocblas_rot_kernel<NB = ROCBLAS_ROT_NB = 512, Tex = float> + rocblas_rot_kernel_calc (real variant),
// projects/rocblas/library/src/blas1/rocblas_rot_kernels.hpp
// Non-batched, unit increments, c and s by value (host pointer mode): the batch loop, load_ptr_batch,
// load_scalar, offset, stride and inc arguments are removed (ix = iy = tid).
#include "rocblas_common.h"

#define NB 512

__forceinline__ __device__ void rocblas_rot_kernel_calc(rocblas_int n, float* x, float* y, float c, float s)
{
    int64_t tid = blockIdx.x * blockDim.x + threadIdx.x;

    if(tid < n)
    {
        int64_t ix    = tid;
        int64_t iy    = tid;
        float   tempx = float(c * x[ix]) + float(s * y[iy]);
        float   tempy = float(c * y[iy]) - float((s)*x[ix]);
        y[iy]         = float(tempy);
        x[ix]         = float(tempx);
    }
}

extern "C" __global__ __launch_bounds__(NB) void rb_rot(rocblas_int n, float* x, float* y, float c, float s)
{
    rocblas_rot_kernel_calc(n, x, y, c, s);
}
