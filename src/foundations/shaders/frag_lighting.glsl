
in vec4 f_frag_color;


void main()
{
    Material f_m = f_materials[0];
    Light f_l = f_lights[0];
    fo_frag_color = f_m.specular + f_l.diffuse;
}
