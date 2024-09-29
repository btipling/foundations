
void main()
{
    Light f_ls[10];
    f_ls[0] = f_lights[0];
    vec4 f_texture_color = texture(f_samp, f_tc);
    fo_frag_color = f_blinn_phong_lighting_texture(f_texture_color, f_ls, 1, f_global_ambient, 50.0);
}