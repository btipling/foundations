
uniform mat4 light_data;
out vec3 fo_light_1_dir;
out vec3 fo_light_2_dir;
out vec3 fo_light_1_attenuation;
out vec3 fo_light_2_attenuation;
uniform mat4 f_object_m;

uniform mat4 f_shadow_m;
out vec4 fo_shadow_coord;

void main()
{
    vec3 f_light_1_pos = light_data[0].xyz;
    vec3 f_light_2_pos = light_data[2].xyz;

    fo_light_1_attenuation = light_data[1].xyz;
    fo_light_2_attenuation = light_data[3].xyz;

    mat4 m_matrix = f_object_m * mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix* f_xup)));

    vec4 f_main_pos = m_matrix * f_xup * vec4(f_position.xyz, 1.0);
    fo_vert = f_main_pos.xyz;
    fo_normals = normalize(f_norm_matrix * f_normals);
    fo_light_1_dir = f_light_1_pos - fo_vert;
    fo_light_2_dir = f_light_2_pos - fo_vert;

    fo_shadow_coord = f_shadow_m * f_main_pos;
    gl_Position =  f_mvp * f_main_pos;
    f_tc = f_texture_coords;
}
