
in vec4 f_frag_color;
in vec3 fo_normals;

void main()
{
   fo_frag_color = vec4(fo_normals.xyz, 0.1) * 0.5 + 0.5; 
}
