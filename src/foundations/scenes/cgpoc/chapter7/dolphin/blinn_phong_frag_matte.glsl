
in vec4 fo_shadow_coord;

void main()
{
    Light f_ls[10];
    f_ls[0] = f_lights[0];
    vec4 f_texture_color = texture(f_samp_1, f_tc);
    float f_not_in_shadow = textureProj(f_shadow_texture, fo_shadow_coord);
    if (f_not_in_shadow != 1.0) {
        f_ls[0].ambient = vec4(0.0, 0.0, 0.0, 0.0);
    }
    fo_frag_color = f_blinn_phong_lighting_texture_matte(f_texture_color, f_ls, 1, f_global_ambient);
}