#version 460 
#extension GL_ARB_bindless_texture : require

in vec2 f_tc;
in vec3 fo_normal;
in vec3 fo_vert;
in vec3 fo_light;

in vec3 f_view_p;
in vec4 fo_pos;
out vec4 fo_frag_color;
uniform vec3 f_waterdata;


//#include "src/foundations/shaders/camera.glsl"
//#include "src/foundations/shaders/material.glsl"
//#include "src/foundations/shaders/light.glsl"
//#include "src/foundations/scenes/cgpoc/chapter15/simulating_water/surface_wave.glsl"

layout(bindless_sampler) uniform sampler2D f_reflection;
layout(bindless_sampler) uniform sampler2D f_refraction;

void main()
{
    // vec4 f_water_occlusion = vec4(0.192, 0.259, 0.396, 1.0);
    vec4 f_water_occlusion = vec4(0.259, 0.388, 0.596, 1.0);
    float f_occlusion_start = 0.01 * 1000.0;
    float f_occlusion_end = 0.125 * 1000.0;
    float f_frag_distance = length(f_view_p.xyz);
    float f_occlusion_factor = clamp(((f_occlusion_end - f_frag_distance) / (f_occlusion_end - f_occlusion_start)), 0.0, 1.0);
    

    vec3 f_N = f_estimate_wave_normal(0.8, 32.0, 2.0);
    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    
    Light f_light = f_lights[0];
    Material f_mat = f_materials[1];

    vec3 f_L = normalize(fo_light);
    vec3 f_H = normalize(f_L + f_V).xyz;

    float cosTheta = dot(f_L, f_N);
    float cosPhi = dot(f_H, f_N);

    vec3 f_ambient = ((f_global_ambient * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
    vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);
    vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess * 40);
    
    vec2 refract_tc = (vec2(fo_pos.x, fo_pos.y))/(2.0 * fo_pos.w) + 0.5;
    vec2 reflect_tc = (vec2(fo_pos.x, -fo_pos.y))/(2.0 * fo_pos.w) + 0.5;
    vec4 f_reflection_color = texture(f_reflection, reflect_tc);
    vec4 f_refraction_color = texture(f_refraction, refract_tc);
    vec4 f_surface_color = (0.2 * f_refraction_color) + (0.8 * f_reflection_color);

    f_surface_color =  f_surface_color * vec4(f_ambient.xyz + f_diffuse.xyz, 1.0)  + vec4(f_specular, 1.0);
    if (f_waterdata[0] <= 0) {
        f_surface_color = mix(f_water_occlusion, f_surface_color, f_occlusion_factor);
    }
    fo_frag_color = f_surface_color;
}
