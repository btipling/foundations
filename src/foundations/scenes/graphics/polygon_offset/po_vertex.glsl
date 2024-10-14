uniform mat4 f_object_m;

void main()
{
    mat4 m_matrix = f_object_m * mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix* f_xup)));
    vec4 f_main_pos = m_matrix * f_xup * vec4(f_position.xyz, 1.0);
    fo_normal = normalize(f_norm_matrix * f_normal);
    gl_Position =  f_mvp * f_main_pos;
}