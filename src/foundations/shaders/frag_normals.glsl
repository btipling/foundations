

void main()
{
   fo_frag_color = vec4(fo_normals.xyz, 1.0) * 0.5 + 0.5; 
}
