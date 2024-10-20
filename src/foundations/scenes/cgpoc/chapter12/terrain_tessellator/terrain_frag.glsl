#version 460 
#extension GL_ARB_bindless_texture : require

in vec2 f_tc_tes;
in vec3 f_normal_tes;
out vec4 fo_frag_color;

// layout(bindless_sampler) uniform sampler2D f_terrain_samp;

void main()
{
   // fo_frag_color = texture(f_terrain_samp, f_tc_tes);
   fo_frag_color = vec4(normalize(f_normal_tes.xyz), 1.0) * 0.5 + 0.5; 
}
