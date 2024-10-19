#version 460

in vec2 f_tc[];
out vec2 f_tc_tcs[];
layout(vertices = 16) out;

void main(void)
{
    int f_TL = 32;
    if (gl_InvocationID == 0) {
        gl_TessLevelOuter[0] = f_TL;
        gl_TessLevelOuter[1] = f_TL;
        gl_TessLevelOuter[2] = f_TL;
        gl_TessLevelOuter[3] = f_TL;
        gl_TessLevelInner[0] = f_TL;
        gl_TessLevelInner[1] = f_TL;
    }
    gl_out[gl_InvocationID].gl_Position = gl_in[gl_InvocationID].gl_Position;
    f_tc_tcs[gl_InvocationID] = f_tc[gl_InvocationID];
}