#version 460 
#extension GL_ARB_bindless_texture : require

in vec2 f_tc;
in vec3 fo_normal;
in vec3 fo_vert;
in vec3 fo_light;

out vec4 fo_frag_color;

layout(bindless_sampler) uniform samplerCube f_skybox;

in vec3 fo_skybox_tc;

void main()
{
   fo_frag_color = texture(f_skybox, fo_skybox_tc);
}
