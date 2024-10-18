#version 460 core

//#include "src/foundations/shaders/f_calc_new_normal.glsl"

void main()
{
    
    vec4 f_texture_color = texture(f_samp_3, f_tc);
    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = f_calc_new_normal();
    Light f_light = f_lights[0];
    Material f_mat = f_materials[0];

    vec3 f_L = normalize(fo_lightdir.xyz);
    vec3 f_H = normalize(f_L + f_V).xyz;


    float cosTheta = dot(f_L, f_N);
    float cosPhi = dot(f_H, f_N);

    vec3 f_ambient = ((f_global_ambient * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
    vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);
    vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess * 4.0);

    fo_frag_color = f_texture_color * vec4((f_ambient + f_diffuse + f_specular), 1.0); 
}
