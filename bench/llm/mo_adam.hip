// From MIOpen (ROCm/rocm-libraries @ 207bc1a58e95, MIT; see LICENSES.md and README.md).
// AdamContiguous + AdamInternal<PTYPE, CTYPE>, projects/miopen/src/kernels/MIOpenAdam.cpp
// Build options of solver/adam/adam.cpp for a float parameter tensor, no AMP, no step tensor:
// -DPTYPE=float -DGTYPE=float -DCTYPE=float -DMIOPEN_USE_FP32=1. Nothing is removed.
#include "miopen_common.h"

#define PTYPE float
#define CTYPE float

template <typename T1, typename T2>
inline __device__ void AdamInternal(T1* param_in,
                                    T1* param_out,
                                    T1* exp_avg_in,
                                    T1* exp_avg_out,
                                    T1* exp_avg_sq_in,
                                    T1* exp_avg_sq_out,
                                    T1* max_exp_avg_sq_in,
                                    T1* max_exp_avg_sq_out,
                                    T2 grad,
                                    T2 lr,
                                    T2 beta1,
                                    T2 beta2,
                                    T2 weight_decay,
                                    T2 eps,
                                    uint32_t step,
                                    bool amsgrad,
                                    bool maximize,
                                    bool adamw,
                                    size_t gid)
{
    T2 param      = static_cast<T2>(param_in[gid]);
    T2 exp_avg    = static_cast<T2>(exp_avg_in[gid]);
    T2 exp_avg_sq = static_cast<T2>(exp_avg_sq_in[gid]);

    __builtin_assume(exp_avg_sq >= 0 && exp_avg_sq <= 1);
    __builtin_assume(beta1 >= 0);
    __builtin_assume(beta2 >= 0);

    T2 bias_correction1 = 1 - pow(beta1, step);
    T2 bias_correction2 = 1 - pow(beta2, step);

    if(maximize)
        grad = -grad;
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfloat-equal"
#endif
    if(weight_decay != 0)
    {
        if(adamw)
            param -= lr * weight_decay * param;
        else
            grad += param * weight_decay;
    }
#ifdef __clang__
#pragma clang diagnostic pop
#endif

    exp_avg    = exp_avg * beta1 + grad * (1 - beta1);
    exp_avg_sq = exp_avg_sq * beta2 + grad * grad * (1 - beta2);

    T2 denom;
    if(amsgrad)
    {
        T2 max_exp_avg_sq = static_cast<T2>(max_exp_avg_sq_in[gid]);
        __builtin_assume(max_exp_avg_sq >= 0 && max_exp_avg_sq <= 1);

        max_exp_avg_sq          = max(max_exp_avg_sq, exp_avg_sq);
        max_exp_avg_sq_out[gid] = static_cast<T1>(max_exp_avg_sq);
        denom                   = sqrt(max_exp_avg_sq) / sqrt(bias_correction2) + eps;
    }
    else
    {
        denom = sqrt(exp_avg_sq) / sqrt(bias_correction2) + eps;
    }

    T2 step_size = lr / bias_correction1;
    param        = param - step_size * exp_avg / denom;

    param_out[gid]      = static_cast<T1>(param);
    exp_avg_out[gid]    = static_cast<T1>(exp_avg);
    exp_avg_sq_out[gid] = static_cast<T1>(exp_avg_sq);
}

extern "C" __global__ void mo_adam(PTYPE* param_in,
                                   PTYPE* param_out,
                                   PTYPE* grad_in,
                                   PTYPE* exp_avg_in,
                                   PTYPE* exp_avg_out,
                                   PTYPE* exp_avg_sq_in,
                                   PTYPE* exp_avg_sq_out,
                                   PTYPE* max_exp_avg_sq_in,
                                   PTYPE* max_exp_avg_sq_out,
                                   float lr,
                                   float beta1,
                                   float beta2,
                                   float weight_decay,
                                   float eps,
                                   uint32_t step,
                                   bool amsgrad,
                                   bool maximize,
                                   bool adamw,
                                   size_t input_size)
{
    size_t gid = blockIdx.x * blockDim.x + threadIdx.x;
    size_t gsz = gridDim.x * blockDim.x;

    for(; gid < input_size; gid += gsz)
    {
        CTYPE grad = static_cast<CTYPE>(grad_in[gid]);

        AdamInternal<PTYPE, CTYPE>(param_in,
                                   param_out,
                                   exp_avg_in,
                                   exp_avg_out,
                                   exp_avg_sq_in,
                                   exp_avg_sq_out,
                                   max_exp_avg_sq_in,
                                   max_exp_avg_sq_out,
                                   grad,
                                   lr,
                                   beta1,
                                   beta2,
                                   weight_decay,
                                   eps,
                                   step,
                                   amsgrad,
                                   maximize,
                                   adamw,
                                   gid);
    }
}
