#version 460 
#extension GL_ARB_bindless_texture : require

in vec4 f_frag_color;
in vec3 fo_normal;
in vec3 fo_vert;
in vec3 fo_pos;

out vec4 fo_frag_color;

layout(bindless_sampler) uniform sampler3D f_tex_samp;

void main()
{ 
   vec4 f_texture_color = texture(f_tex_samp, fo_pos/2.0 + 0.5);

   vec4 f_surf_color = vec4(0.65, 0.65, 0.74, 1.0);
   fo_frag_color = mix(f_texture_color, f_surf_color, 0.75 - fo_pos.x * 0.25);
}
