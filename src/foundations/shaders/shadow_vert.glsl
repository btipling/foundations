uniform mat4 f_shadow_m;

void main()
{
    mat4 f_transform = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    vec4 f_pos = f_shadow_m * f_transform * f_xup * vec4(f_position.xyz, 1.0);
    gl_Position = f_pos;
}
