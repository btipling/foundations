#version 460 core


//#include "src/foundations/shaders/vertex_outs.glsl"

//#include "src/foundations/shaders/camera.glsl"

uniform float f_offset;

void main()
{
    gl_Position = f_mvp * vec4(f_offset, 0.0, 0.0, 1.0);
    f_frag_color = vec4(0.0, 0.0, 1.0, 1.0);
}