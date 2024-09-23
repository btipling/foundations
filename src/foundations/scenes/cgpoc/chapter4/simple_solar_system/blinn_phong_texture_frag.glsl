in vec3 fo_light_dir;
void main()
{
    Light f_ls[10];
    f_ls[0] = f_lights[0];
    f_ls[0].direction = vec4(fo_light_dir, 1.0);
    vec4 f_texture_color = texture(f_samp, f_tc);
    fo_frag_color = f_texture_color * f_blinn_phong_lighting_no_mat(f_ls, 1, vec4(0.0, 0.0, 0.0, 1.0), 32.0);
}