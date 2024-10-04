uniform uint f_material_selection; 
uniform mat4 f_object_m;

out vec4 fo_light_1_coord_0;
out vec4 fo_light_1_coord_1;
out vec4 fo_light_1_coord_2;
out vec4 fo_light_1_coord_3;
out vec4 fo_light_1_coord_4;
out vec4 fo_light_1_coord_5;

out vec4 fo_light_2_coord_0;
out vec4 fo_light_2_coord_1;
out vec4 fo_light_2_coord_2;
out vec4 fo_light_2_coord_3;
out vec4 fo_light_2_coord_4;
out vec4 fo_light_2_coord_5;

out vec4 fo_all_ambient;

layout(std140, binding = 1) uniform SceneData
{
    vec4 light_1_position;
    vec4 light_1_attenuation;
    mat4 light_1_views[6];
    vec4 light_2_position;
    vec4 light_2_attenuation;
    mat4 light_2_views[6];
} f_scene_data;


void main()
{

    vec3 f_light_1_pos = f_scene_data.light_2_position.xyz;
    vec3 f_light_2_pos = f_scene_data.light_2_position.xyz;

    vec3 f_light_1_attenuation = f_scene_data.light_1_attenuation.xyz;
    vec3 f_light_2_attenuation = f_scene_data.light_2_attenuation.xyz;

    mat4 m_matrix = f_object_m * mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix * f_xup)));

    Material f_m = f_materials[f_material_selection];

    vec4 f_P = m_matrix * f_xup * vec4(f_position.xyz, 1.0);
    vec3 f_N = normalize(f_norm_matrix * f_normals);

    
    vec3 f_l_dirs[2] = vec3[2](f_light_1_pos, f_light_2_pos);
    vec3 f_l_at[2] = vec3[2](f_light_1_attenuation, f_light_2_attenuation);
    f_frag_color = vec4(0.0, 0.0, 0.0, 1.0);

    uint num_lights = 2;
    uint i = 0;
    fo_all_ambient = f_global_ambient * f_m.ambient;
    do {
        Light f_l = f_lights[i];
        vec3 f_distance_vector = f_l_dirs[i] - f_P.xyz;
        vec3 f_attenuations = f_l_at[i];
        float f_d = length(f_distance_vector);
        float f_attenuation = 1.0/(f_attenuations[0] + f_attenuations[1] * f_d + f_attenuations[2] * f_d * f_d);
        vec3 f_L = normalize(f_distance_vector);

        vec3 f_V = normalize(f_camera_pos.xyz - f_P.xyz);
        vec3 f_R = reflect(-f_L, f_N);

        vec3 f_ambient = ((f_global_ambient * f_m.ambient) + (f_attenuation * f_l.ambient * f_m.ambient)).xyz;
        vec3 f_diffuse = f_l.diffuse.xyz * f_m.diffuse.xyz * max(dot(f_N, f_L), 0.0) * f_attenuation;
        vec3 f_specular = f_m.specular.xyz * f_l.specular.xyz * pow(max(dot(f_R, f_V), 0.0), f_m.shininess) * f_attenuation;

        gl_Position =  f_mvp * f_P;
        f_tc = f_texture_coords;
        
        fo_normals = f_N;
        f_frag_color = f_frag_color + vec4((f_ambient + f_diffuse + f_specular), 0.0);
        i += 1;
    } while (i < num_lights);
    

    fo_light_1_coord_0 = f_scene_data.light_1_views[0] * f_P;
    fo_light_1_coord_1 = f_scene_data.light_1_views[1] * f_P;
    fo_light_1_coord_2 = f_scene_data.light_1_views[2] * f_P;
    fo_light_1_coord_3 = f_scene_data.light_1_views[3] * f_P;
    fo_light_1_coord_4 = f_scene_data.light_1_views[4] * f_P;
    fo_light_1_coord_5 = f_scene_data.light_1_views[5] * f_P;

    fo_light_2_coord_0 = f_scene_data.light_2_views[0] * f_P;
    fo_light_2_coord_1 = f_scene_data.light_2_views[1] * f_P;
    fo_light_2_coord_2 = f_scene_data.light_2_views[2] * f_P;
    fo_light_2_coord_3 = f_scene_data.light_2_views[3] * f_P;
    fo_light_2_coord_4 = f_scene_data.light_2_views[4] * f_P;
    fo_light_2_coord_5 = f_scene_data.light_2_views[5] * f_P;
}
