
out vec3 fo_light_dir;

void main()
{
    mat4 m_matrix = f_model_transform * mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix* f_xup)));

    vec4 f_main_pos = m_matrix * f_xup * vec4(f_position.xyz, 1.0);
    fo_vert = f_main_pos.xyz;
    fo_normals = f_norm_matrix * f_normals;

    fo_light_dir = vec3(0.0, 0.0, 0.0) - fo_vert;

    gl_Position =  f_mvp * f_main_pos;
    f_tc = f_texture_coords;
}
