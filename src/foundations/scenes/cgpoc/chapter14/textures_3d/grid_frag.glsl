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

layout(bindless_sampler) uniform sampler2DShadow f_shadow_texture;
layout(bindless_sampler) uniform sampler2D f_grid_samp;
layout(bindless_sampler) uniform sampler2D f_normal_samp;

in vec4 fo_shadow_coord;

float f_lookup(float f_ox, float f_oy)
{
    float f_t = textureProj(
        f_shadow_texture,
        fo_shadow_coord + vec4(
            f_ox * 0.0001 * fo_shadow_coord.w,
            f_oy * 0.0001 * fo_shadow_coord.w,
            0,
            0.0
        ));
    return f_t;
}

vec3 calcNewNormal()
{
	vec3 normal = vec3(1,0,0);
	vec3 tangent = vec3(0,0, 1);
	vec3 bitangent = cross(tangent, normal) * 1;
	mat3 tbn = mat3(tangent, bitangent, normal);
	vec3 retrievedNormal = texture(f_normal_samp, f_tc).xyz;
	retrievedNormal = retrievedNormal * 2.0 - 1.0;
	vec3 newNormal = tbn * retrievedNormal;
	newNormal = normalize(newNormal);
	return newNormal;
}

void main()
{
    vec4 f_texture_color = texture(f_grid_samp, f_tc);
    vec3 f_N = calcNewNormal();
    
    Light f_light = f_lights[0];
    Material f_mat = f_materials[0];

    vec3 f_L = normalize(fo_light);

    float cosTheta = dot(f_L, f_N);

    vec3 f_ambient = ((f_global_ambient * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
    vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);

    float f_shadow_factor = 0.0;
    float swidth = 2.5;
    vec2 f_offset = mod(floor(gl_FragCoord.xy), 2.0) * swidth;
    f_shadow_factor += f_lookup(-1.5 * swidth + f_offset.x, 1.5 * swidth - f_offset.y);
    f_shadow_factor += f_lookup(-1.5 * swidth + f_offset.x, -0.5 * swidth - f_offset.y);
    f_shadow_factor += f_lookup(0.5 * swidth + f_offset.x, 1.5 * swidth - f_offset.y);
    f_shadow_factor += f_lookup(0.5 * swidth + f_offset.x, -0.5 * swidth - f_offset.y);
    f_shadow_factor = f_shadow_factor/4.0;

    if (fo_normal[0] < 0.01 && fo_normal[1] > 0.99) {
        f_shadow_factor = 1.0;
    }

    fo_frag_color = f_texture_color * vec4((f_ambient.xyz + f_shadow_factor * (f_diffuse.xyz)), 1.0);
}
