uniform mat4 f_pointer_transform;
mat4 f_mvp = p_matrix * v_matrix;

out vec4 f_frag_color;
out vec3 fo_normals;

void main()
{
    mat4 f_transform = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    f_transform = f_pointer_transform * f_transform;
    vec4 pos = f_mvp * f_transform * vec4(f_position.xyz, 1.0);
    gl_Position = pos;
    f_frag_color = f_i_color;
    fo_normals = normalize(transpose(inverse(mat3(f_pointer_transform))) * f_normals);
}