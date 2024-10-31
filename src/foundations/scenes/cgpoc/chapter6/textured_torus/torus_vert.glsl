
mat4 f_cubemap_xup = (mat4(
    vec4(0, 1, 0, 0),
    vec4(0, 0, 1, 0),
    vec4(1, 0, 0, 0),
    vec4(0, 0, 0, 1)
));

out vec3 fo_pos;

void main()
{
    mat4 m_matrix = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    vec4 f_main_pos = m_matrix * f_xup * vec4(f_position.xyz, 1.0);
    mat3 f_norm_matrix = transpose(inverse(mat3(f_cubemap_xup * m_matrix * f_xup)));

    fo_normal = normalize(f_norm_matrix * f_normal);
    fo_vert =  (f_cubemap_xup * f_main_pos).xyz;
    fo_pos = f_position.xyz;
    
    gl_Position =  f_mvp * f_main_pos;
}
