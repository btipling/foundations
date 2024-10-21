#version 460 
#extension GL_ARB_bindless_texture : require

in vec2 f_tc_tes;
out vec4 fo_frag_color;

//#include "src/foundations/shaders/camera.glsl"

layout(bindless_sampler) uniform sampler2D f_terrain_samp;



void main()
{
   fo_frag_color = texture(f_terrain_samp, f_tc_tes);
}
