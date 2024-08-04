#version 460 core
in vec4 fo_color;

out vec4 fo_frag_color;

void main()
{
   fo_frag_color = fo_color; 
} 