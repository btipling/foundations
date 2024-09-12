#version 460 core

in vec4 f_varying_color;
out vec4 fo_frag_color;

void main()
{
   fo_frag_color = f_varying_color; 
} 