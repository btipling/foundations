uniform uint f_material_selection;
in vec3 fo_light_1_dir;
in vec3 fo_light_2_dir;

void main()
{
    Material f_m = f_materials[f_material_selection];

    Light f_ls[2] = Light[2](f_lights[0], f_lights[1]);
    vec3 f_l_dirs[2] = vec3[2](fo_light_1_dir, fo_light_2_dir);
    fo_frag_color = f_blinn_phong_lighting(f_m, f_ls, f_l_dirs);
}
