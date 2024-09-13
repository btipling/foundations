
void main()
{
    float f_i = gl_InstanceID + f_tf;
    float f_a = sin(203.0 * f_i/8000.0) * 403.0;
    float f_b = sin(301.0 * f_i/4001.0) * 401.0;
    float f_c = sin(400.0 * f_i/6003.0) * 405.0;
    mat4 f_transform = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat4 f_localRotX = buildRotateX(2*f_i);
    mat4 f_localRotY = buildRotateY(2*f_i);
    mat4 f_localRotZ = buildRotateZ(2*f_i);
    mat4 f_localTrans = buildTranslate(f_a, f_b, f_c);
    mat4 newM_matrix = f_localTrans * f_localRotX * f_localRotY * f_localRotZ;
    vec4 f_pos = f_mvp * newM_matrix * f_transform * vec4(f_position.xyz, 1.0);
    gl_Position = f_pos;
    f_varying_color = ((vec4(f_position.xyz, 1.0) * 2.0) - 1.0) * 0.5 + vec4(0.5, 0.5, 0.5, 0.5);
}