uniform mat4 f_mvp;

out vec4 f_frag_color;

void main()
{
    mat4 f_transform = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    vec4 f_pos = f_mvp *  f_transform * vec4(f_position.xyz, 1.0);
    gl_Position = f_pos;
    f_frag_color = ((vec4(f_position.xyz, 1.0) * 2.0) - 1.0) * 0.5 + vec4(0.5, 0.5, 0.5, 0.5);
}