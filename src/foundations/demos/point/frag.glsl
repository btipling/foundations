#version 460 core

out vec4 fo_frag_color;

void main()
{
   if (gl_FragCoord.x < 950) {
      fo_frag_color = vec4(1.0, 0.0, 0.0, 1.0); 
   } else {
      fo_frag_color = vec4(0.0, 0.0, 1.0, 1.0); 
   }
} 