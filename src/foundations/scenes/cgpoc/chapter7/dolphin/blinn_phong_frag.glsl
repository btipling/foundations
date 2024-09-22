
void main()
{
    Material f_m = f_materials[0];
    Light f_ls[10];
    f_ls[0] = f_lights[0];
    vec4 f_texture_color = texture(f_samp, f_tc);
    vec4 f_global_ambient = vec4(0.7, 0.7, 0.7, 1.0);
    fo_frag_color = f_texture_color * 0.5 + f_blinn_phong_lighting(f_m, f_ls, 1, f_global_ambient) * 0.5;
}