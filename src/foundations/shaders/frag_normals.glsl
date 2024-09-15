#version 460 core
in vec4 f_frag_color;
in vec3 fo_normals;

out vec4 fo_frag_color;

void main()
{
   fo_frag_color = vec4(fo_normals.xyz, 0.1) * 0.5 + 0.5; 
} 