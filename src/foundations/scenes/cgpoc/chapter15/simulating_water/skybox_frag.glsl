#version 460 
#extension GL_ARB_bindless_texture : require

in vec2 f_tc;
in vec3 fo_normal;
in vec3 fo_vert;
in vec3 fo_light;

out vec4 fo_frag_color;
uniform int f_underwater;

//#include "src/foundations/shaders/camera.glsl"

layout(bindless_sampler) uniform samplerCube f_skybox;

in vec3 fo_skybox_tc;

void main()
{
   if (f_underwater > 0) {
      fo_frag_color = vec4(0.0, 0.0, 0.2, 1.0);
   } else {
      fo_frag_color = texture(f_skybox, fo_skybox_tc);
   }
}
