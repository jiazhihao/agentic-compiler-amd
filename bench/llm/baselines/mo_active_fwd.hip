#include "miopen_common.h"
typedef float __attribute__((ext_vector_type(4))) f4;
extern "C" __global__ void mo_active_fwd(const float* bot, float* top, const int map_size_aligned,
                                         float gamma, float beta, float alpha)
{
    const unsigned int tid = blockIdx.x * LSZ + threadIdx.x;
    if(tid >= (unsigned)map_size_aligned)
        return;
    const size_t index = (size_t)tid * 4;
    f4 d = *((const f4*)(bot + index));
    f4 r;
    r.x = d.x * ((d.x > 0) ? 1.0f : alpha);
    r.y = d.y * ((d.y > 0) ? 1.0f : alpha);
    r.z = d.z * ((d.z > 0) ? 1.0f : alpha);
    r.w = d.w * ((d.w > 0) ? 1.0f : alpha);
    *((f4*)(top + index)) = r;
}
