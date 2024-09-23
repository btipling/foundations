
void main()
{
    Material f_m = f_materials[0];
    Light f_ls[10];
    f_ls[0] = f_lights[0];
    fo_frag_color = f_blinn_phong_lighting(f_m, f_ls, 1, f_global_ambient);
}