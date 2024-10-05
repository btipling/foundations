uniform uint f_material_selection;
in vec3 fo_light_1_dir;
in vec3 fo_light_2_dir;
in vec3 fo_light_1_attenuation;
in vec3 fo_light_2_attenuation;

in vec4 fo_light_1_z_pos_0;
in vec4 fo_light_1_y_neg_1;
in vec4 fo_light_1_z_neg_2;
in vec4 fo_light_1_y_pos_3;
in vec4 fo_light_1_x_pos_4;
in vec4 fo_light_1_x_neg_5;

in vec4 fo_light_2_z_pos_0;
in vec4 fo_light_2_y_neg_1;
in vec4 fo_light_2_z_neg_2;
in vec4 fo_light_2_y_pos_3;
in vec4 fo_light_2_x_pos_4;
in vec4 fo_light_2_x_neg_5;

vec4 f_blinn_phong_lighting(Material f_mat, Light f_lights[10], uint num_lights, vec4 f_ambient_light) {
    num_lights = min(num_lights, 10u);

    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);

    vec4 rv = vec4(0.0, 0.0, 0.0, 1.0);

    float f_can_get_light_from_z_pos_0 = dot(f_N, vec3(0, 0, 1));
    float f_can_get_light_from_y_neg_1 = dot(f_N, vec3(0, -1, 0));
    float f_can_get_light_from_z_neg_2 = dot(f_N, vec3(0, 0, -1));
    float f_can_get_light_from_y_pos_3 = dot(f_N, vec3(0, 1, 0));
    float f_can_get_light_from_x_pos_4 = dot(f_N, vec3(1, 0, 0));
    float f_can_get_light_from_x_neg_5 = dot(f_N, vec3(-1, 0, 0));
    
    uint i = 0;
    do {
        Light f_light = f_lights[i];
        float f_d = length(f_light.direction.xyz);
        
        float f_attenuation = 1.0/(f_light.attenuation_constant + f_light.attenuation_linear * f_d + f_light.attenuation_quadratic * f_d * f_d);
        vec3 f_L = normalize(f_light.direction.xyz);
        vec3 f_H = normalize(f_L + f_V).xyz;

        float cosTheta = dot(f_L, f_N);
        float cosPhi = dot(f_H, f_N);

        vec3 f_ambient = ((f_ambient_light * f_mat.ambient) + (f_light.ambient * f_mat.ambient * f_attenuation)).xyz;
        vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0) * f_attenuation;
        vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess * 4.0) * f_attenuation;

        float bias = 0.0;
        float not_in_shadow = 1.0;
        float normal_offset = 0.5;
        if (i == 0) {
            if (f_can_get_light_from_z_pos_0 < normal_offset) {
                not_in_shadow = textureProj(f_shadow_texture0, fo_light_1_z_pos_0, bias);
            }
            if (f_can_get_light_from_y_neg_1 < normal_offset) {
                if (not_in_shadow == 1.0) {
                    not_in_shadow = textureProj(f_shadow_texture1, fo_light_1_y_neg_1, bias);
                }
            }
            if (f_can_get_light_from_z_neg_2 < normal_offset) {
                if (not_in_shadow == 1.0) {
                    not_in_shadow = textureProj(f_shadow_texture2, fo_light_1_z_neg_2, bias);
                }
            }
            if (f_can_get_light_from_y_pos_3 < normal_offset) {
                if (not_in_shadow == 1.0) {
                    not_in_shadow = textureProj(f_shadow_texture3, fo_light_1_y_pos_3, bias);
                }
            }
            if (f_can_get_light_from_x_pos_4 < normal_offset) {
                if (not_in_shadow == 1.0) {
                    not_in_shadow = textureProj(f_shadow_texture4, fo_light_1_x_pos_4, bias);
                }
            }
            if (f_can_get_light_from_x_neg_5 < normal_offset) {
                if (not_in_shadow == 1.0) {
                    not_in_shadow = textureProj(f_shadow_texture5, fo_light_1_x_neg_5, bias);
                }
            }
        } else {
            if (f_can_get_light_from_z_pos_0 < normal_offset) {
                not_in_shadow = textureProj(f_shadow_texture6, fo_light_2_z_pos_0, bias);
            }
            if (f_can_get_light_from_y_neg_1 < normal_offset) {
                if (not_in_shadow == 1.0) {
                   not_in_shadow = textureProj(f_shadow_texture7, fo_light_2_y_neg_1, bias);
                }
            }
            if (f_can_get_light_from_z_neg_2 < normal_offset) {
                if (not_in_shadow == 1.0) {
                    not_in_shadow = textureProj(f_shadow_texture8, fo_light_2_z_neg_2, bias);
                }
            }
            if (f_can_get_light_from_y_pos_3 < normal_offset) {
                if (not_in_shadow == 1.0) {
                    not_in_shadow = textureProj(f_shadow_texture9, fo_light_2_y_pos_3, bias);
                }
            }
            if (f_can_get_light_from_x_pos_4 < normal_offset) {
                if (not_in_shadow == 1.0) {
                    not_in_shadow = textureProj(f_shadow_texture10, fo_light_2_x_pos_4, bias);
                }
            }
            if (f_can_get_light_from_x_neg_5 < normal_offset) {
                if (not_in_shadow == 1.0) {
                    not_in_shadow = textureProj(f_shadow_texture11, fo_light_2_x_neg_5, bias);
                }
            }
        }
        if (not_in_shadow == 1.0) {
            rv = rv + vec4((f_ambient + f_diffuse + f_specular), 0.0);
        } else {
            rv = rv + vec4(f_ambient, 0.0);
        }
        i += 1;
    } while (i < num_lights);
    return rv;
}

void main()
{
    Material f_m = f_materials[f_material_selection];
    Light f_ls[10];
    f_ls[0] = f_lights[0];
    f_ls[0].direction = vec4(fo_light_1_dir, 0.0);
    f_ls[0].attenuation_constant = fo_light_1_attenuation[0];
    f_ls[0].attenuation_linear = fo_light_1_attenuation[1];
    f_ls[0].attenuation_quadratic = fo_light_1_attenuation[2];

    f_ls[1] = f_lights[1];
    f_ls[1].direction = vec4(fo_light_2_dir, 0.0);
    f_ls[1].attenuation_constant = fo_light_2_attenuation[0];
    f_ls[1].attenuation_linear = fo_light_2_attenuation[1];
    f_ls[1].attenuation_quadratic = fo_light_2_attenuation[2];

    fo_frag_color = f_blinn_phong_lighting(f_m, f_ls, 2, f_global_ambient);
}
