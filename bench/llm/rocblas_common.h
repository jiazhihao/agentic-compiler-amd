// Device helpers copied from rocBLAS (ROCm/rocm-libraries @ 207bc1a58e95, MIT, see LICENSES.md),
// instantiated for T = float. Sources:
//   projects/rocblas/library/src/include/device_macros.hpp   (WARP_32, WARP_64)
//   projects/rocblas/library/src/blas1/rocblas_reduction.hpp (rocblas_log2ui, rocblas_wavefront_reduce,
//                                                             rocblas_dot_block_reduce)
//   projects/rocblas/library/src/blas1/reduction.hpp         (rocblas_reduction_s, rocblas_reduction,
//                                                             rocblas_reduce_sum, rocblas_sum_reduce)
// Only the complex / half / bfloat16 overloads were left out; the code that remains is unchanged.
#pragma once
#include <hip/hip_runtime.h>
#include <cstdint>

typedef int rocblas_int;

#define WARP_32 32
#define WARP_64 64

static constexpr int rocblas_log2ui(int x)
{
    unsigned int ax = (unsigned int)x;
    int          v  = 0;
    while(ax >>= 1)
    {
        v++;
    }
    return v;
}

template <int N, typename T>
__inline__ __device__ T rocblas_wavefront_reduce(T val)
{
    constexpr int WFBITS = rocblas_log2ui(N);
    int           offset = 1 << (WFBITS - 1);
#pragma unroll
    for(int i = 0; i < WFBITS; i++)
    {
        val += __shfl_down(val, offset);
        offset >>= 1;
    }
    return val;
}

template <int WARP, int NB, typename T>
__inline__ __device__ T rocblas_dot_block_reduce(T val)
{
    __shared__ T psums[WARP];

    rocblas_int wavefront = threadIdx.x / WARP;
    rocblas_int wavelet   = threadIdx.x % WARP;

    if(wavefront == 0)
        psums[wavelet] = T(0);
    __syncthreads();

    val = rocblas_wavefront_reduce<WARP>(val); // sum over wavefront
    if(wavelet == 0)
        psums[wavefront] = val; // store sum for wavefront

    __syncthreads(); // Wait for all wavefront reductions

    // ensure wavefront was run
    static constexpr rocblas_int num_wavefronts = NB / WARP;
    // single warp of either size will doing final sum so test with smaller constraint
    static_assert(num_wavefronts <= WARP_32);

    val = (threadIdx.x < num_wavefronts) ? psums[wavelet] : T(0);
    if(wavefront == 0)
        val = rocblas_wavefront_reduce<num_wavefronts>(val); // sum wavefront sums

    return val;
}

// Recursively compute reduction
template <rocblas_int k, typename REDUCE, typename T>
struct rocblas_reduction_s
{
    __forceinline__ __device__ void operator()(rocblas_int tx, T* x) const
    {
        // Reduce the lower half with the upper half
        if(tx < k)
            REDUCE{}(x[tx], x[tx + k]);
        __syncthreads();

        // Recurse down with k / 2
        rocblas_reduction_s<k / 2, REDUCE, T>{}(tx, x);
    }
};

// leaf node for terminating recursion
template <typename REDUCE, typename T>
struct rocblas_reduction_s<0, REDUCE, T>
{
    __forceinline__ __device__ void operator()(rocblas_int tx, T* x) const {}
};

template <rocblas_int NB, typename REDUCE, typename T>
__attribute__((flatten)) __device__ void rocblas_reduction(rocblas_int tx, T* x)
{
    static_assert(NB > 1 && !(NB & (NB - 1)), "NB must be a power of 2");
    __syncthreads();
    rocblas_reduction_s<NB / 2, REDUCE, T>{}(tx, x);
}

struct rocblas_reduce_sum
{
    template <typename T>
    __forceinline__ __device__ void operator()(T& __restrict__ a, const T& __restrict__ b) const
    {
        a += b;
    }
};

template <rocblas_int NB, typename T>
__attribute__((flatten)) __device__ void rocblas_sum_reduce(rocblas_int tx, T* x)
{
    rocblas_reduction<NB, rocblas_reduce_sum>(tx, x);
}
