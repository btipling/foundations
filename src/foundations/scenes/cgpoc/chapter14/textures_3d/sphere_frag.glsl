#version 460 

in vec4 f_frag_color;
in vec3 fo_normal;
in vec3 fo_vert;

out vec4 fo_frag_color;

void main()
{ 
   vec4 f_surf_color = vec4(1.0, 0.549, 0.231, 1.0);
   fo_frag_color = mix(f_frag_color, f_surf_color, 0.75 - fo_vert.x * 1.25);
}
