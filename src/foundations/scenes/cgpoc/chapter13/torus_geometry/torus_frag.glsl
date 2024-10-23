#version 460 

in vec4 fo_frag_color_g;
out vec4 fo_frag_color;

void main()
{
   fo_frag_color = fo_frag_color_g;
}
