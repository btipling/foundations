uniform uint f_material_selection; 
in vec3 fo_light_1_dir;

void main()
{
    Material f_m = f_materials[f_material_selection];
    Light f_l = f_lights[0];
    
    fo_frag_color = f_phong_lighting(f_m, f_l, fo_light_1_dir);
}
