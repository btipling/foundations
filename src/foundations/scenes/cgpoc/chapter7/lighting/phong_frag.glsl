uniform uint f_material_selection; 
in vec3 fo_light_1_dir;
in vec3 fo_light_2_dir;

void main()
{
    Material f_m = f_materials[f_material_selection];
    Light f_ls[10];
    f_ls[0] = f_lights[0];
    f_ls[0].direction = vec4(fo_light_1_dir, 1.0);
    f_ls[1] = f_lights[1];
    f_ls[1].direction = vec4(fo_light_2_dir, 1.0);
    fo_frag_color = f_phong_lighting(f_m, f_ls, 2);
}
