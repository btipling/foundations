in vec3 f_cubemap_f_tc;

void main()
{
   fo_frag_color = texture(f_cubemap, f_cubemap_f_tc);
}
