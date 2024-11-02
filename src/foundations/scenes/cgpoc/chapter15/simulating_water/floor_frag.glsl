#version 460 

in vec2 f_tc;
in vec3 fo_normal;
in vec3 fo_vert;
in vec3 fo_light;

in vec3 f_view_p;
out vec4 fo_frag_color;

uniform vec3 f_waterdata;

//#include "src/foundations/shaders/camera.glsl"
//#include "src/foundations/shaders/material.glsl"
//#include "src/foundations/shaders/light.glsl"

void main()
{
    vec4 f_water_occlusion = vec4(0.0, 0.0, 0.035, 1.0);
    float f_occlusion_start = 0.01 * 1000.0;
    float f_occlusion_end = 0.1 * 1000.0;
    float f_frag_distance = length(f_view_p.xyz);
    float f_occlusion_factor = clamp(((f_occlusion_end - f_frag_distance) / (f_occlusion_end - f_occlusion_start)), 0.0, 1.0);

    float f_z = floor(fo_vert.z) / 8.0;
    float f_y = floor(fo_vert.y) / 8.0;

    vec4 f_surface_color;
    if (mod(f_z, 2.0) <= 0.95 && mod(f_y, 2.0) > 0.95 || mod(f_z, 2.0) > 0.95 && mod(f_y, 2.0) <= 0.95) {
        f_surface_color = vec4(0.01, 0.01, 0.01, 1.0);
    } else {
        f_surface_color = vec4(0.9, 0.9, 0.9, 0.9);
    }
    vec3 f_N = vec3(1.0, 0.0, 0.0);
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

    f_surface_color = f_surface_color * vec4(f_ambient.xyz + f_diffuse.xyz, 1.0)  + vec4(f_specular, 1.0);
    if (f_waterdata[0] > 0) {
        f_surface_color = mix(f_water_occlusion, f_surface_color, f_occlusion_factor);
    }
    fo_frag_color = f_surface_color;
}
