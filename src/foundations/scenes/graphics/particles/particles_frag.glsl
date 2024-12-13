#version 460 

in vec3 f_normal_g;
in vec3 fo_vert_g;
in vec3 fo_light_g;
in vec4 fo_frag_color_g;

//#include "src/foundations/shaders/camera.glsl"
//#include "src/foundations/shaders/material.glsl"
//#include "src/foundations/shaders/light.glsl"

out vec4 fo_frag_color;

void main()
{ 
   vec3 f_V = normalize(f_camera_pos.xyz - fo_vert_g);
   vec3 f_N = normalize(f_normal_g);
   Light f_light = f_lights[0];
   Material f_mat = f_materials[0];
   
   float f_d = length(fo_light_g);

   vec3 f_L = normalize(fo_light_g);
   vec3 f_H = normalize(f_L + f_V).xyz;

   float cosTheta = dot(f_L, f_N);
   float cosPhi = dot(f_H, f_N);

   vec3 f_ambient = ((f_global_ambient * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
   vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);
   vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess * 4.0);

   fo_frag_color = fo_frag_color_g * vec4((f_ambient + f_diffuse + f_specular), 1.0);
}
