// From MIOpen (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// MIOpenBatchNormFwdInferSpatialEst + BNFwdInferSpatialImpl,
// projects/miopen/src/kernels/MIOpenBatchNormFwdInferSpatial.cpp, with the pass-through activation_op of
// projects/miopen/src/kernels/bnorm_spatial_activation_functions.hpp and the float4 vector type of
// vector_types.hpp.
// Build options of solver/batchnorm/forward_inference.cpp for a float NCHW tensor with h * w a multiple
// of 4 and no fused activation: -DMIOPEN_USE_FP32=1 -DMIO_BN_GRP0=1 -DMIO_BN_GRP1=256 -DMIO_BN_GRP2=1
// -DMIO_LAYOUT_NHWC=0 -DMIO_BN_VECTORIZE=1 -DMIO_BN_VEC_SIZE=4 -DMIOPEN_NRN_OP_ID=0
// (miopenActivationPASTHRU). Nothing is removed; the NHWC branches are dead under if constexpr.
#include "miopen_common.h"

#define MIO_BN_GRP0 1
#define MIO_BN_GRP1 256
#define MIO_BN_GRP2 1
#define MIO_LAYOUT_NHWC 0
#define MIO_BN_VEC_SIZE 4

namespace miopen {
namespace batchnorm {
// activation_op for neuron_op_type::pasthru (MIOPEN_NRN_OP_ID = 0)
template <typename FpPrecType>
__forceinline__ __device__ FpPrecType activation_op(FpPrecType const& tmp, FpPrecType const&, FpPrecType const&)
{
    return tmp;
}
} // namespace batchnorm
} // namespace miopen

// determine block size using parameters passed from the host
constexpr int blockSize = MIO_BN_GRP0 * MIO_BN_GRP1 * MIO_BN_GRP2;

// define types for vectorized loads/stores (miopen::mapped_vector_type<float, 4>::type)
using FLOAT_VEC_TYPE       = FLOAT __attribute__((ext_vector_type(MIO_BN_VEC_SIZE)));
using FLOAT_ACCUM_VEC_TYPE = FLOAT_ACCUM __attribute__((ext_vector_type(MIO_BN_VEC_SIZE)));

template <unsigned int vecSizeX, unsigned int vecSizeY>
__device__ __forceinline__ void BNFwdInferSpatialImpl(unsigned int tidx,
                                                      unsigned int tidy,
                                                      const FLOAT* in,
                                                      FLOAT* out,
                                                      const FLOAT_ACCUM* mean,
                                                      const FLOAT_ACCUM* invVariance,
                                                      const FLOAT_ACCUM* scale,
                                                      const FLOAT_ACCUM* bias,
                                                      unsigned int batchSize,
                                                      unsigned int cStride,
                                                      unsigned int hwStride,
                                                      unsigned int batchStride,
                                                      FLOAT_ACCUM alpha,
                                                      FLOAT_ACCUM beta)
{
    FLOAT_ACCUM inhat[MIO_BN_VEC_SIZE];
    FLOAT value[MIO_BN_VEC_SIZE];

    // loop over the batches
    // NOTE: We use zlocalsize = 1 and zgridsize = min(batchSize, maxGridSizeToFillTheGPU). So the
    // idea here is to use the blocks in z-dimension to cover the batch dimension first, and then
    // each block will loop over the remaining batches with stride of gridDim.z if necessary.
    for(unsigned int n = blockIdx.z; n < batchSize; n += gridDim.z)
    {
        // load input value
        const unsigned int batchIndex =
            (n * batchStride) + (tidx * cStride * vecSizeX) + (tidy * hwStride * vecSizeY);
        *(reinterpret_cast<FLOAT_VEC_TYPE*>(value)) =
            *(reinterpret_cast<const FLOAT_VEC_TYPE*>(in + batchIndex));

        // perform batchnorm and activation
#pragma unroll
        for(unsigned int i = 0; i < MIO_BN_VEC_SIZE; ++i)
        {
            inhat[i] = (CVT_FLOAT2ACCUM(value[i]) - mean[i]) * invVariance[i];
            inhat[i] = scale[i] * inhat[i] + bias[i];
            inhat[i] = miopen::batchnorm::activation_op<FLOAT_ACCUM>(inhat[i], alpha, beta);
            value[i] = CVT_ACCUM2FLOAT(inhat[i]);
        }

        // write output value
        *(reinterpret_cast<FLOAT_VEC_TYPE*>(out + batchIndex)) =
            *(reinterpret_cast<const FLOAT_VEC_TYPE*>(value));
    }
}

extern "C" __global__ void __launch_bounds__(blockSize)
    mo_bn_infer(const FLOAT* __restrict in,
                FLOAT* __restrict out,
                const FLOAT_ACCUM* __restrict estimatedMean,
                const FLOAT_ACCUM* __restrict estimatedVariance,
                const FLOAT_ACCUM* __restrict scale,
                const FLOAT_ACCUM* __restrict bias,
                double epsilon,
                unsigned int c,
                unsigned int hw,
                unsigned int batchSize,
                unsigned int cStride,
                unsigned int hwStride,
                unsigned int batchStride,
                FLOAT_ACCUM alpha,
                FLOAT_ACCUM beta)
{
    unsigned int tidx = blockIdx.x * MIO_BN_GRP0 + threadIdx.x;
    unsigned int tidy = blockIdx.y * MIO_BN_GRP1 + threadIdx.y;
    unsigned int tidz = blockIdx.z;

    // decide vector sizes based on problem layout
    constexpr unsigned int vecSizeX = MIO_LAYOUT_NHWC ? MIO_BN_VEC_SIZE : 1;
    constexpr unsigned int vecSizeY = MIO_LAYOUT_NHWC ? 1 : MIO_BN_VEC_SIZE;

    // skip execution for out-of-bound threads
    if(tidx * vecSizeX >= c || tidy * vecSizeY >= hw || tidz >= batchSize)
    {
        return;
    }

    // indices for current thread
    unsigned int adjIndex = tidx * vecSizeX;

    // batch parameters and values for current thread
    FLOAT_ACCUM mean[MIO_BN_VEC_SIZE];
    FLOAT_ACCUM variance[MIO_BN_VEC_SIZE];
    FLOAT_ACCUM pscale[MIO_BN_VEC_SIZE];
    FLOAT_ACCUM pbias[MIO_BN_VEC_SIZE];
    FLOAT_ACCUM invVariance[MIO_BN_VEC_SIZE];

    if constexpr(MIO_LAYOUT_NHWC)
    {
        *(reinterpret_cast<FLOAT_ACCUM_VEC_TYPE*>(mean)) =
            *(reinterpret_cast<const FLOAT_ACCUM_VEC_TYPE*>(estimatedMean + adjIndex));
        *(reinterpret_cast<FLOAT_ACCUM_VEC_TYPE*>(variance)) =
            *(reinterpret_cast<const FLOAT_ACCUM_VEC_TYPE*>(estimatedVariance + adjIndex));
        *(reinterpret_cast<FLOAT_ACCUM_VEC_TYPE*>(pscale)) =
            *(reinterpret_cast<const FLOAT_ACCUM_VEC_TYPE*>(scale + adjIndex));
        *(reinterpret_cast<FLOAT_ACCUM_VEC_TYPE*>(pbias)) =
            *(reinterpret_cast<const FLOAT_ACCUM_VEC_TYPE*>(bias + adjIndex));
    }
    else // NCHW layout
    {
        const auto mean_val     = estimatedMean[adjIndex];
        const auto variance_val = estimatedVariance[adjIndex];
        const auto pscale_val   = scale[adjIndex];
        const auto pbias_val    = bias[adjIndex];

#pragma unroll
        for(unsigned int i = 0; i < MIO_BN_VEC_SIZE; ++i)
        {
            mean[i]     = mean_val;
            variance[i] = variance_val;
            pscale[i]   = pscale_val;
            pbias[i]    = pbias_val;
        }
    }

#pragma unroll
    for(unsigned int i = 0; i < MIO_BN_VEC_SIZE; ++i)
    {
        invVariance[i] = rsqrt(fabs(variance[i] + static_cast<FLOAT_ACCUM>(epsilon)));
    }

    BNFwdInferSpatialImpl<vecSizeX, vecSizeY>(tidx,
                                              tidy,
                                              in,
                                              out,
                                              mean,
                                              invVariance,
                                              pscale,
                                              pbias,
                                              batchSize,
                                              cStride,
                                              hwStride,
                                              batchStride,
                                              alpha,
                                              beta);
}
