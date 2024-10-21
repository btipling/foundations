#version 460

//#include "src/foundations/shaders/camera.glsl"

layout(vertices = 1) out;

uniform mat4 f_terrain_m;

in vec2 f_tc[];
out vec2 f_tc_tcs[];


void main(void)
{
    float f_sub_divs = 32.0;
    if (gl_InvocationID == 0) {
        vec4 p0 = gl_in[0].gl_Position;
        vec4 p1 = gl_in[1].gl_Position;
        vec4 p2 = gl_in[2].gl_Position;
        p0 = f_mvp * f_terrain_m * vec4(p0[1], p0[2], p0[0], 1.0);
        p1 = f_mvp * f_terrain_m * vec4(p1[1], p1[2], p1[0], 1.0);
        p2 = f_mvp * f_terrain_m * vec4(p2[1], p2[2], p2[0], 1.0);
        p0 = p0 / p0.w;
        p1 = p1 / p1.w;
        p2 = p2 / p2.w;
        float f_width = length(p2.xyz - p0.xyz) * f_sub_divs + 1.0;
        float f_height = length(p1.xyz - p0.xyz) * f_sub_divs + 1.0;
        float f_TL = max(f_width, f_height);
        gl_TessLevelOuter[0] = f_TL;
        gl_TessLevelOuter[1] = f_TL;
        gl_TessLevelOuter[2] = f_TL;
        gl_TessLevelOuter[3] = f_TL;
        gl_TessLevelInner[0] = f_TL;
        gl_TessLevelInner[1] = f_TL;
    }
    f_tc_tcs[gl_InvocationID] = f_tc[gl_InvocationID];
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
}