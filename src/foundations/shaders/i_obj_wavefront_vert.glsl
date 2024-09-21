
void main()
{
    mat4 f_transform = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat4 f_xup = mat4(
        vec4(0, 0, -1, 0),
        vec4(1, 0, 0, 0),
        vec4(0, 1, 0, 0),
        vec4(0, 0, 0, 1)
    );
    vec4 f_pos = f_mvp * f_transform * f_xup * vec4(f_position.xyz, 1.0);
    gl_Position = f_pos;
    f_tc = f_texture_coords;
    f_frag_color = f_i_color;
    fo_normals = mat3(f_mvp * f_transform * f_xup) * f_normals;
}
