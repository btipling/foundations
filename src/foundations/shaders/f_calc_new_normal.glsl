vec3 f_calc_new_normal() {
    vec3 f_n_normal = normalize(fo_normal);
    vec3 f_n_tangent = normalize(fo_tangent.xyz);
    vec3 f_n_bitangent = fo_tangent.w * normalize(cross(f_n_tangent, f_n_normal));
    mat3 f_n_tbn = mat3(f_n_tangent, f_n_bitangent, f_n_normal);
    vec3 f_n_map_normal = (vec4(texture(f_samp_2, f_tc).xyz, 1.0)).xyz;
    f_n_map_normal = f_n_map_normal * 2.0 - 1.0;
    vec3 f_n_new_normal = f_n_tbn * f_n_map_normal;
    f_n_new_normal = normalize(f_n_new_normal);
    return f_n_new_normal; 
}
