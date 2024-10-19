#version 460

//#include "src/foundations/shaders/camera.glsl"

uniform mat4 f_grid_m;

layout (quads, equal_spacing, ccw) in;

void main(void)
{
    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;
    
    gl_Position = f_mvp * f_grid_m * vec4(0, v, u, 1.0);
}