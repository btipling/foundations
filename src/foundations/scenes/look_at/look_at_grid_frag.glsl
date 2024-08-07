#version 460 core
in vec4 fo_color;
in vec3 fo_normals;

out vec4 fo_frag_color;

void main()
{
   fo_frag_color = fo_color; 
} 