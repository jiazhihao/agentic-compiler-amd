// From MIOpen (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// MIOpenActiveFwdLite, projects/miopen/src/kernels/MIOpenNeuron.cpp, with ActivationFunction ->
// ActivationFunction_Leaky_ReLU from projects/miopen/src/kernels/activation_functions.hpp.
// Build options of solver/activ/fwd_0.cpp for a packed float tensor whose length is a multiple of 4:
// -DLITE -DMIOPEN_USE_FP32=1 -DMIOPEN_READ_UNIT=4 -DMIOPEN_READ_TYPE=FP_TYPE4 -DLOCAL_SIZE=256
// -DMIOPEN_NRN_OP_ID=8 (MIOPEN_NEURON_LEAKY_RELU, miopenActivationLEAKYRELU).
// Zero offsets: the bot_offset / top_offset arguments are removed.
#include "miopen_common.h"

#define FP_TYPE float
#define FP_TYPE4 float __attribute__((ext_vector_type(4))) // miopen::mapped_vector_type<FP_TYPE, 4>::type
#define MIOPEN_READ_UNIT 4
#define MIOPEN_READ_TYPE FP_TYPE4
#define LOCAL_SIZE 256
#define MIOPEN_NEURON_LEAKY_RELU 8 // alpha * x | x <= 0; x | x > 0
#define MIOPEN_NRN_OP_ID MIOPEN_NEURON_LEAKY_RELU

template <typename T, size_t N>
__forceinline__ __device__ void ActivationFunction_Leaky_ReLU(T (&__restrict__ res)[N],
                                                              const T (&__restrict__ data)[N],
                                                              const T /*gamma*/,
                                                              const T /*beta*/,
                                                              const T alpha)
{
    for(unsigned int i = 0; i < N; ++i)
    {
        res[i] = data[i] * ((data[i] > 0) ? static_cast<T>(1) : alpha);
    }
}

template <typename T, size_t N>
__forceinline__ __device__ void ActivationFunction(T (&__restrict__ res)[N],
                                                   const T (&__restrict__ data)[N],
                                                   const T gamma,
                                                   const T beta,
                                                   const T alpha)
{
    static_assert(N * sizeof(T) <= 16);
    if constexpr(MIOPEN_NRN_OP_ID == MIOPEN_NEURON_LEAKY_RELU)
    {
        ActivationFunction_Leaky_ReLU(res, data, gamma, beta, alpha);
    }
}

extern "C" __global__ void mo_active_fwd(const FP_TYPE* bot,
                                         FP_TYPE* top,
                                         const int map_size_aligned,
                                         FP_TYPE gamma,
                                         FP_TYPE beta,
                                         FP_TYPE alpha)
{
    const unsigned int tid   = blockIdx.x * LOCAL_SIZE + threadIdx.x;
    const unsigned int index = tid * MIOPEN_READ_UNIT;

    if(tid >= map_size_aligned)
        return;

    FP_TYPE data[MIOPEN_READ_UNIT];
    FP_TYPE response[MIOPEN_READ_UNIT];

    *((MIOPEN_READ_TYPE*)data) = *((const MIOPEN_READ_TYPE*)(bot + index));

    ActivationFunction(response, data, gamma, beta, alpha);

    *((MIOPEN_READ_TYPE*)(top + index)) = *((MIOPEN_READ_TYPE*)response);
}
