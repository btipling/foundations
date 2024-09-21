
uniform mat4 f_cube_transform;

void main()
{
    mat4 f_transform = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat4 f_world_transform = f_cube_transform * f_transform;
    vec4 f_pos = f_mvp * f_world_transform * vec4(f_position.xyz, 1.0);
    gl_Position = f_pos;
    f_frag_color = f_i_color;
    fo_normals = normalize(transpose(inverse(mat3(f_cube_transform))) * f_normals);
}