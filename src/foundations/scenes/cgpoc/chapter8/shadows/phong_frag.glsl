uniform uint f_material_selection; 
in vec3 fo_light_1_dir;
in vec3 fo_light_2_dir;
in vec3 fo_light_1_attenuation;
in vec3 fo_light_2_attenuation;

in vec4 fo_light_1_coord_0;
in vec4 fo_light_1_coord_1;
in vec4 fo_light_1_coord_2;
in vec4 fo_light_1_coord_3;
in vec4 fo_light_1_coord_4;
in vec4 fo_light_1_coord_5;

in vec4 fo_light_2_coord_0;
in vec4 fo_light_2_coord_1;
in vec4 fo_light_2_coord_2;
in vec4 fo_light_2_coord_3;
in vec4 fo_light_2_coord_4;
in vec4 fo_light_2_coord_5;


vec4 f_phong_lighting(Material f_mat, Light f_lights[10], uint num_lights, vec4 f_ambient_light) {
    num_lights = min(num_lights, 10u);
    
    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);

    vec4 rv = vec4(0.0, 0.0, 0.0, 1.0);

    uint i = 0;
    do {
        Light f_light = f_lights[i];
        float f_d = length(f_light.direction.xyz);
        
        float f_attenuation = 1.0/(f_light.attenuation_constant + f_light.attenuation_linear * f_d + f_light.attenuation_quadratic * f_d * f_d);
        vec3 f_L = normalize(f_light.direction.xyz);
        vec3 f_R = reflect(-f_L, f_N);

        float cosTheta = dot(f_L, f_N);
        float cosPhi = dot(f_V, f_R);

        vec3 f_ambient = ((f_ambient_light * f_mat.ambient) + (f_light.ambient * f_mat.ambient * f_attenuation)).xyz;
        vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0) * f_attenuation;
        vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess) * f_attenuation;
    
        float bias = 0.0;
        float not_in_shadow = 1.0;
        if (i == 0) {
            not_in_shadow = textureProj(f_shadow_texture0, fo_light_1_coord_0, bias);
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture1, fo_light_1_coord_1, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture2, fo_light_1_coord_2, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture3, fo_light_1_coord_3, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture4, fo_light_1_coord_4, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture5, fo_light_1_coord_5, bias);
            }
        } else {
            not_in_shadow = textureProj(f_shadow_texture6, fo_light_2_coord_0, bias);
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture7, fo_light_2_coord_1, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture8, fo_light_2_coord_2, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture9, fo_light_2_coord_3, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture10, fo_light_2_coord_4, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture11, fo_light_2_coord_5, bias);
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
    
    
    fo_frag_color = f_phong_lighting(f_m, f_ls, 2, f_global_ambient);
}
