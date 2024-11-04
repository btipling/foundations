#version 460

layout(local_size_x = 1) in;

layout(std430, binding = 3) buffer ComputeData {
    float f_v1[6];
    float f_v2[6];
    float f_out[6];
};

void main()
{
    uint f_this_run = gl_GlobalInvocationID.x;
    f_out[f_this_run] = f_v1[f_this_run] + f_v2[f_this_run];
}