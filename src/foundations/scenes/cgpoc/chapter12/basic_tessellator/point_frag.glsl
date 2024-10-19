#version 460 

//#include "src/foundations/shaders/frag_ins.glsl"

out vec4 fo_frag_color;

void main()
{
   fo_frag_color = f_frag_color;
}
