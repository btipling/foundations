#version 460 
#extension GL_ARB_bindless_texture : require

in vec2 f_tc_tes;
out vec4 fo_frag_color;

layout(bindless_sampler) uniform sampler2D f_samp_2;

void main()
{
   fo_frag_color = texture(f_samp_2, f_tc_tes);
}
