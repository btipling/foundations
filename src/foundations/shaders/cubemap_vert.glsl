out vec3 f_cubemap_f_tc;

mat4 f_cubemap_xup = mat4(
    vec4(0, 1, 0, 0),
    vec4(0, 0, 1, 0),
    vec4(1, 0, 0, 0),
    vec4(0, 0, 0, 1)
);

void main()
{
    mat4 f_cubemap_t = mat4(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        f_camera_pos[0], f_camera_pos[1], f_camera_pos[2], 1
    );
    mat4 f_transform = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    vec4 f_pos = f_mvp * f_cubemap_t * f_transform * f_xup * vec4(f_position.xyz, 1.0);
    gl_Position = f_pos;
    f_cubemap_f_tc =  (f_transform * f_cubemap_xup * vec4(f_position.xyz, 1.0)).xyz;
    f_tc = f_texture_coords;
    f_frag_color = f_i_color;
    fo_normals = f_normals;
}
