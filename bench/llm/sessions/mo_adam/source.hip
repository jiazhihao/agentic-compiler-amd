#include "miopen_common.h"

#ifndef EPT
#define EPT 1
#endif

static inline __device__ double ipow_d(double b, uint32_t e)
{
    double r = 1.0;
    while(e)
    {
        if(e & 1u)
            r *= b;
        b *= b;
        e >>= 1;
    }
    return r;
}

extern "C" __global__ void mo_adam(float* param_in,
                                   float* param_out,
                                   float* grad_in,
                                   float* exp_avg_in,
                                   float* exp_avg_out,
                                   float* exp_avg_sq_in,
                                   float* exp_avg_sq_out,
                                   float* max_exp_avg_sq_in,
                                   float* max_exp_avg_sq_out,
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
    size_t base = ((size_t)blockIdx.x * blockDim.x + threadIdx.x) * EPT;
    if(base >= input_size)
        return;

    float bc1   = (float)(1.0 - ipow_d((double)beta1, step));
    float bc2   = (float)(1.0 - ipow_d((double)beta2, step));
    float sbc2  = sqrtf(bc2);
    float ss    = lr / bc1;
    float omb1  = 1 - beta1;
    float omb2  = 1 - beta2;
    bool  wd    = weight_decay != 0;

    float p[EPT], g[EPT], m[EPT], v[EPT], mx[EPT];
    size_t n = input_size - base;
    if(n > EPT)
        n = EPT;

    if(n == EPT)
    {
        for(int i = 0; i < EPT; ++i)
        {
            g[i] = grad_in[base + i];
            p[i] = param_in[base + i];
            m[i] = exp_avg_in[base + i];
            v[i] = exp_avg_sq_in[base + i];
        }
        if(amsgrad)
            for(int i = 0; i < EPT; ++i)
                mx[i] = max_exp_avg_sq_in[base + i];
        for(int i = 0; i < EPT; ++i)
        {
            float grad = g[i], param = p[i];
            if(maximize)
                grad = -grad;
            if(wd)
            {
                if(adamw)
                    param -= lr * weight_decay * param;
                else
                    grad += param * weight_decay;
            }
            float ea = m[i] * beta1 + grad * omb1;
            float es = v[i] * beta2 + grad * grad * omb2;
            float denom;
            if(amsgrad)
            {
                float mm = max(mx[i], es);
                mx[i]    = mm;
                denom    = sqrtf(mm) / sbc2 + eps;
            }
            else
                denom = sqrtf(es) / sbc2 + eps;
            p[i] = param - ss * ea / denom;
            m[i] = ea;
            v[i] = es;
        }
        if(amsgrad)
            for(int i = 0; i < EPT; ++i)
                max_exp_avg_sq_out[base + i] = mx[i];
        for(int i = 0; i < EPT; ++i)
            param_out[base + i] = p[i];
        for(int i = 0; i < EPT; ++i)
            exp_avg_out[base + i] = m[i];
        for(int i = 0; i < EPT; ++i)
            exp_avg_sq_out[base + i] = v[i];
    }
    else
    {
        for(size_t i = 0; i < n; ++i)
        {
            size_t gid = base + i;
            float grad = grad_in[gid], param = param_in[gid];
            float ea0 = exp_avg_in[gid], es0 = exp_avg_sq_in[gid];
            if(maximize)
                grad = -grad;
            if(wd)
            {
                if(adamw)
                    param -= lr * weight_decay * param;
                else
                    grad += param * weight_decay;
            }
            float ea = ea0 * beta1 + grad * omb1;
            float es = es0 * beta2 + grad * grad * omb2;
            float denom;
            if(amsgrad)
            {
                float mm = max(max_exp_avg_sq_in[gid], es);
                max_exp_avg_sq_out[gid] = mm;
                denom = sqrtf(mm) / sbc2 + eps;
            }
            else
                denom = sqrtf(es) / sbc2 + eps;
            param_out[gid]      = param - ss * ea / denom;
            exp_avg_out[gid]    = ea;
            exp_avg_sq_out[gid] = es;
        }
    }
}
