#version 460 
#extension GL_ARB_bindless_texture : require

in vec2 f_tc;
in vec3 fo_normal;
in vec3 fo_vert;
in vec3 fo_light;

in vec3 f_view_p;
in vec4 fo_pos;
out vec4 fo_frag_color;


layout(bindless_sampler) uniform sampler2D f_reflection;

//#include "src/foundations/shaders/camera.glsl"
//#include "src/foundations/shaders/material.glsl"
//#include "src/foundations/shaders/light.glsl"

void main()
{
    vec3 f_N = vec3(-1.0, 0.0, 0.0);
    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    
    Light f_light = f_lights[0];
    Material f_mat = f_materials[0];

    vec3 f_L = normalize(fo_light);
    vec3 f_H = normalize(f_L + f_V).xyz;

    float cosTheta = dot(f_L, f_N);
    float cosPhi = dot(f_H, f_N);

    vec3 f_ambient = ((f_global_ambient * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
    vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);
    vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess * 40.0);
    
    vec2 reflect_tc = (vec2(fo_pos.x, fo_pos.y))/(2.0 * fo_pos.w) + 0.5;
    vec4 f_reflection_color = texture(f_reflection, reflect_tc);
    vec4 f_blue = vec4(0.0, 0.25, 1.0, 1.0);;
    vec4 f_surface_color = (0.7 * f_blue) + (0.3 * f_reflection_color);
    fo_frag_color = f_surface_color + vec4(f_ambient.xyz + f_diffuse.xyz, 1.0) * 0.5 + vec4(f_specular, 1.0);
}
