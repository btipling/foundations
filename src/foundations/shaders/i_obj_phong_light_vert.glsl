mat4 f_mvp = p_matrix * v_matrix;
out vec2 f_tc;
out vec4 f_frag_color;
out vec3 fo_normals;
out vec3 fo_vert;
out vec3 fo_lightdir;

uniform vec3 f_light_pos;

void main()
{
    mat4 m_matrix = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix)));

    vec4 f_main_pos = m_matrix * vec4(f_position.xyz, 1.0);
    fo_vert = vec3(f_main_pos);
    fo_normals = f_norm_matrix * f_normals;
    fo_lightdir = f_light_pos - fo_vert;

    gl_Position =  f_mvp * f_main_pos;
    f_tc = f_texture_coords;
}
