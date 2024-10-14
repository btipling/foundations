vec3 f_calc_new_normal() {
    vec3 f_n_normal = normalize(fo_normal);
    vec3 f_n_tangent = normalize(fo_tangent.xyz);
    f_n_tangent = normalize(f_n_tangent - dot(f_n_tangent, f_n_normal) * f_n_normal);
    vec3 f_n_bitangent = fo_tangent.w * cross(f_n_tangent, f_n_normal);
    mat3 f_n_tbn = mat3(f_n_tangent, f_n_bitangent, f_n_normal);
    vec3 f_n_map_normal = texture(f_samp, f_tc).xyz;
    f_n_map_normal = f_n_map_normal * 2.0 - 1.0;
    vec3 f_n_new_normal = f_n_tbn * f_n_map_normal;
    f_n_new_normal = normalize(f_n_new_normal);
    return f_n_new_normal; 
}

void main()
{
    
    vec4 f_texture_color = texture(f_samp_1, f_tc);
    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = f_calc_new_normal();
    Light f_light = f_lights[0];
    Material f_mat = f_materials[0];
    float f_d = length(fo_lightdir.xyz);

    vec3 f_L = normalize(f_light.direction.xyz);
    vec3 f_H = normalize(f_L + f_V).xyz;


    float cosTheta = dot(f_L, f_N);
    float cosPhi = dot(f_H, f_N);

    vec3 f_ambient = ((f_global_ambient * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
    vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);
    vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess * 4.0);

    fo_frag_color = f_texture_color * vec4((f_ambient + f_diffuse + f_specular), 1.0); 
}
