

void main()
{
   fo_frag_color = vec4(normalize(fo_normal.xyz), 1.0) * 0.5 + 0.5; 
}
