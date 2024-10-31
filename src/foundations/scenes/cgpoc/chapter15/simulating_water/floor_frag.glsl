#version 460 

in vec2 f_tc;
in vec3 fo_normal;
in vec3 fo_vert;
in vec3 fo_light;

in vec3 f_view_p;
out vec4 fo_frag_color;


//#include "src/foundations/shaders/camera.glsl"
//#include "src/foundations/shaders/material.glsl"
//#include "src/foundations/shaders/light.glsl"

void main()
{
    float f_z = floor(fo_vert.z) / 8.0;
    float f_y = floor(fo_vert.y) / 8.0;

    if (mod(f_z, 2.0) <= 0.95 && mod(f_y, 2.0) > 0.95 || mod(f_z, 2.0) > 0.95 && mod(f_y, 2.0) <= 0.95) {
        fo_frag_color = vec4(0.01, 0.01, 0.01, 1.0);
    } else {
        fo_frag_color = vec4(0.9, 0.9, 0.9, 0.9);
    }
}
