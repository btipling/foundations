
uniform vec3 f_earth_light_pos;

mat4 f_cubemap_xup = (mat4(
    vec4(1, 0, 0, 0),
    vec4(0, 1, 0, 0),
    vec4(0, 0, 1, 0),
    vec4(0, 0, 0, 1)
));

void main()
{
    mat4 m_matrix = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix * f_xup)));
    vec4 f_main_pos = m_matrix * f_xup * vec4(f_position.xyz, 1.0);
    
    fo_vert = f_main_pos.xyz;
    fo_normal = normalize(f_norm_matrix * f_normal);
    f_tc = f_texture_coords;
    f_frag_color = f_i_color;
    fo_tangent = f_cubemap_xup * m_matrix * vec4(f_tangent.xyz, 0);
    fo_tangent.w = f_tangent.w;
    fo_lightdir = (f_cubemap_xup * vec4(f_earth_light_pos, 0)).xyz;
    gl_Position = f_mvp * f_main_pos;
}
