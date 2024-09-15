#version 460 core

out vec4 fo_frag_color;
in vec4 f_frag_color;

void main()
{
   fo_frag_color = f_frag_color;
} 