#include "miopen_common.h"

typedef float f4 __attribute__((ext_vector_type(4), aligned(4)));
typedef float f2 __attribute__((ext_vector_type(2), aligned(4)));

extern "C" __global__ void mo_rope_fwd(const float* __restrict__ x,
                                       const float* __restrict__ cos,
                                       const float* __restrict__ sin,
                                       float* __restrict__ y,
                                       uint64_t output_numel,
                                       uint64_t rotary_numel)
{
    const uint32_t t = threadIdx.x + blockIdx.x * blockDim.x;
    const uint64_t base = (uint64_t)t * 4;
    if(base >= output_numel)
        return;
    const uint64_t kp = rotary_numel >> 1;
    const uint32_t p = t * 2;
    uint32_t fp = p;
    if((uint64_t)p >= kp)
        fp = p % (uint32_t)kp;
    const bool full = base + 4 <= output_numel;
    if(full && (uint64_t)fp + 1 < kp)
    {
        f4 xv = *(const f4*)(x + base);
        f4 c  = *(const f4*)(cos + 2 * (uint64_t)fp);
        f4 s  = *(const f4*)(sin + 2 * (uint64_t)fp);
        f4 r;
        r.x = xv.x * c.x - xv.y * s.x;
        r.y = xv.y * c.y + xv.x * s.y;
        r.z = xv.z * c.z - xv.w * s.z;
        r.w = xv.w * c.w + xv.z * s.w;
        *(f4*)(y + base) = r;
        return;
    }
    {
        f2 xv = *(const f2*)(x + base);
        f2 c  = *(const f2*)(cos + 2 * (uint64_t)fp);
        f2 s  = *(const f2*)(sin + 2 * (uint64_t)fp);
        f2 r;
        r.x = xv.x * c.x - xv.y * s.x;
        r.y = xv.y * c.y + xv.x * s.y;
        *(f2*)(y + base) = r;
    }
    if(full)
    {
        uint32_t f1 = ((uint64_t)fp + 1 < kp) ? fp + 1 : 0;
        f2 xv = *(const f2*)(x + base + 2);
        f2 c  = *(const f2*)(cos + 2 * (uint64_t)f1);
        f2 s  = *(const f2*)(sin + 2 * (uint64_t)f1);
        f2 r;
        r.x = xv.x * c.x - xv.y * s.x;
        r.y = xv.y * c.y + xv.x * s.y;
        *(f2*)(y + base + 2) = r;
    }
}
