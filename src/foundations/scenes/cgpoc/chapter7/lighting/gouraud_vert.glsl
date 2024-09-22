uniform uint f_material_selection; 
uniform vec3 f_light_1_pos;
uniform vec3 f_light_2_pos;

void main()
{
    mat4 m_matrix = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix)));

    Material f_m = f_materials[f_material_selection];

    vec4 f_P = m_matrix * f_xup * vec4(f_position.xyz, 1.0);
    vec3 f_N = normalize(f_norm_matrix * f_normals);

    
    vec3 f_l_dirs[2] = vec3[2](f_light_1_pos, f_light_2_pos);
    f_frag_color = vec4(0.0, 0.0, 0.0, 1.0);
    uint num_lights = 2;
    uint i = 0;
    do {
        Light f_l = f_lights[i];
        vec3 f_L = normalize(f_l_dirs[i] - f_P.xyz);

        vec3 f_V = normalize(-v_matrix[3].xyz - f_P.xyz);
        vec3 f_R = reflect(-f_L, f_N);

        vec4 f_global_ambient = vec4(0.7, 0.7, 0.7, 1.0);
        vec3 f_ambient = ((f_global_ambient * f_m.ambient) + (f_l.ambient * f_m.ambient)).xyz;
        vec3 f_diffuse = f_l.diffuse.xyz * f_m.diffuse.xyz * max(dot(f_N, f_L), 0.0);
        vec3 f_specular = f_m.specular.xyz * f_l.specular.xyz * pow(max(dot(f_R, f_V), 0.0), f_m.shininess);

        gl_Position =  f_mvp * f_P;
        f_tc = f_texture_coords;
        
        fo_normals = f_N;
        f_frag_color = f_frag_color + vec4((f_ambient + f_diffuse + f_specular), 0.0);
    
        i += 1;
    } while (i < num_lights);
}
