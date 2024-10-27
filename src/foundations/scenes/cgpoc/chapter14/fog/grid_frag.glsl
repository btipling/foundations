#version 460 
#extension GL_ARB_bindless_texture : require

in vec2 f_tc;
in vec3 fo_normal;
in vec3 fo_vert;
in vec3 fo_light;

in vec3 f_view_p;
out vec4 fo_frag_color;


//#include "src/foundations/shaders/camera.glsl"
//#include "src/foundations/shaders/material.glsl"
//#include "src/foundations/shaders/light.glsl"

layout(bindless_sampler) uniform sampler2D f_grid_samp;
layout(bindless_sampler) uniform sampler2D f_normal_samp;
// layout(bindless_sampler) uniform sampler2D f_normal_samp;


vec3 calcNewNormal()
{
	vec3 normal = vec3(1,0,0);
	vec3 tangent = vec3(0,0, 1);
	vec3 bitangent = cross(tangent, normal) * -1;
	mat3 tbn = mat3(tangent, bitangent, normal);
	vec3 retrievedNormal = texture(f_normal_samp, f_tc).xyz;
	retrievedNormal = retrievedNormal * 2.0 - 1.0;
	vec3 newNormal = tbn * retrievedNormal;
	newNormal = normalize(newNormal);
	return newNormal;
}

void main()
{
    vec4 f_fog_color = vec4(0.7, 0.8, 0.9, 1.0);
    float f_fog_start = 0.2 * 1000.0;
    float f_fog_end = 0.8 * 1000.0;
    float f_dist = length(f_view_p.xyz);
    float f_fog_factor = clamp((f_fog_end - f_dist)/(f_fog_end - f_fog_start), 0.0, 1.0);


    vec4 f_texture_color = texture(f_grid_samp, f_tc);
    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = calcNewNormal();
    Light f_light = f_lights[0];
    Material f_mat = f_materials[0];

    float f_d = length(fo_light);
    float f_attenuation = 1.0;

    vec3 f_L = normalize(fo_light);
    vec3 f_H = normalize(f_L + f_V).xyz;

    float cosTheta = dot(f_L, f_N);
    float cosPhi = dot(f_H, f_N);

    vec3 f_ambient = ((f_global_ambient * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
    vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);
    vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess * 4.0) * 0.0;

    vec4 f_surf_color = f_texture_color * vec4((f_ambient + f_diffuse + f_specular), 1.0);
    fo_frag_color = mix(f_fog_color, f_surf_color, f_fog_factor);
}
