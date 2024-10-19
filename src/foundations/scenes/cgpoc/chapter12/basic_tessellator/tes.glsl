#version 460

//#include "src/foundations/shaders/camera.glsl"

layout (quads, equal_spacing, cw) in;

void main(void)
{
    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;
    gl_Position = f_mvp * vec4(0, v, u, 1.0);
}