#version 460 

in vec4 f_frag_color;

out vec4 fo_frag_color;

void main()
{ 
   fo_frag_color = f_frag_color;
}
