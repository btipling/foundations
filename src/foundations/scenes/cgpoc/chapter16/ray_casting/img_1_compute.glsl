#version 460

layout(local_size_x = 1) in;
layout(binding=1, rgba8) uniform image2D f_texture;

void main()
{
    vec4 output_color = vec4(1.0, 0.0, 0.0, 1.0);
    ivec2 f_texel = ivec2(gl_GlobalInvocationID.xy);
    imageStore(f_texture, f_texel, output_color);
}