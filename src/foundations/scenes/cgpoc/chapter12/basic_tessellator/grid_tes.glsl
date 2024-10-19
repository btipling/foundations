#version 460

//#include "src/foundations/shaders/camera.glsl"

layout (quads, equal_spacing, ccw) in;

void main(void)
{
    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;
    gl_Position = f_mvp * vec4(u, 0, v, 1.0);
}