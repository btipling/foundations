#version 460 core

out vec4 fo_frag_color;
in vec2 f_tc;

layout (binding=0) uniform sampler2D f_samp;

void main()
{
   fo_frag_color = vec4(1.0, 0.0, 0.0, 1.0); 
} 