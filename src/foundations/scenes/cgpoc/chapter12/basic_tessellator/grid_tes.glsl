#version 460

//#include "src/foundations/shaders/camera.glsl"

layout (quads, equal_spacing, ccw) in;

void main(void)
{
    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;
    mat4 f_scale = mat4(
        2.0, 0.0, 0.0, 0.0,
        0.0, 2.0, 0.0, 0.0,
        0.0, 0.0, 2.0, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
    gl_Position = f_mvp * f_scale * vec4(0, v, u, 1.0);
}