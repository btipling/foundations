#version 460 core
#extension GL_ARB_bindless_texture : require

out vec4 fo_frag_color;
in vec2 f_tc;

layout(bindless_sampler) uniform sampler2D f_samp;

void main()
{
   fo_frag_color = texture(f_samp, f_tc);
} 