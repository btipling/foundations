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

in vec4 fo_all_ambient;
in vec4 fo_l1_all_l2_ambient;
in vec4 fo_l1_ambient_l2_all;
in vec4 fo_l1_all_l2_all;

void main()
{
    uint f_l1_not_in_shadow = 0;
    uint f_l2_not_in_shadow = 0;
    uint num_lights = 2;
    uint i = 0;
    do {
        float bias = 0.0;
        float not_in_shadow = 1.0;
        if (i == 0) {
            not_in_shadow = textureProj(f_shadow_texture0, fo_light_1_z_pos_0, bias);
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture1, fo_light_1_y_neg_1, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture2, fo_light_1_z_neg_2, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture3, fo_light_1_y_pos_3, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture4, fo_light_1_x_pos_4, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture5, fo_light_1_x_neg_5, bias);
            }
        } else {
            not_in_shadow = textureProj(f_shadow_texture6, fo_light_2_z_pos_0, bias);
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture7, fo_light_2_y_neg_1, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture8, fo_light_2_z_neg_2, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture9, fo_light_2_y_pos_3, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture10, fo_light_2_x_pos_4, bias);
            }
            if (not_in_shadow == 1.0) {
                not_in_shadow = textureProj(f_shadow_texture11, fo_light_2_x_neg_5, bias);
            }
        }
        if (not_in_shadow == 1.0) {
            if (i == 0) {
               f_l1_not_in_shadow = 1;
            } else {
               f_l2_not_in_shadow = 1;
            }
        }
        i += 1;
    } while (i < num_lights);

    fo_frag_color = fo_all_ambient;
    if (f_l1_not_in_shadow == 1) {
      if (f_l2_not_in_shadow == 1) {
         fo_frag_color = f_frag_color;
      }
    }
}
