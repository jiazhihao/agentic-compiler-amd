// From rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// rocblas_reduction_kernel_part1<NB = ROCBLAS_NRM2_NB = 512, WIN = rocblas_dot_WIN<float>() = 4,
// FETCH = rocblas_fetch_nrm2<float>, TPtrX = const float*, To = float>,
// projects/rocblas/library/src/blas1/rocblas_asum_nrm2_kernels.hpp, with fetch_abs2 from
// projects/rocblas/library/src/blas1/fetch_template.hpp and rocblas_fetch_nrm2 from rocblas_asum_nrm2.hpp.
// First-stage kernel only (per-block partial sums of squares; part2 sums them and takes the sqrt).
// Non-batched, unit increment: the batch loop, load_ptr_batch, shift, stride and inc arguments are removed.
#include "rocblas_common.h"

#define NB 512
#define WIN 4

template <typename T>
__device__ inline auto fetch_abs2(T A)
{
    return A * A;
}

template <class To>
struct rocblas_fetch_nrm2
{
    template <class Ti>
    __forceinline__ __device__ To operator()(Ti x) const
    {
        return {fetch_abs2(x)};
    }
};

extern "C" __global__ __launch_bounds__(NB) void rb_nrm2(rocblas_int n,
                                                         rocblas_int nblocks,
                                                         const float* x,
                                                         float*       workspace)
{
    int64_t tid = blockIdx.x * NB + threadIdx.x;
    float   sum = 0;

    // sum WIN elements per thread
    int inc = NB * gridDim.x;
    for(int j = 0; j < WIN && tid < n; j++, tid += inc)
        sum += rocblas_fetch_nrm2<float>{}(x[tid]);

    if(warpSize == WARP_32)
        sum = rocblas_dot_block_reduce<WARP_32, NB, float>(sum); // sum reduction only
    else
        sum = rocblas_dot_block_reduce<WARP_64, NB, float>(sum);

    if(threadIdx.x == 0)
        workspace[blockIdx.x] = sum;
}
