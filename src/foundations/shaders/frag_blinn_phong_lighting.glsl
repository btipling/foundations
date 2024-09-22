
void main()
{
    Material f_m = f_materials[0];
    Light f_l = f_lights[0];
    
    fo_frag_color = f_blinn_phong_lighting(f_m, f_l);
}
