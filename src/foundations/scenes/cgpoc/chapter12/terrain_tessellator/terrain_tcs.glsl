#version 460

layout(vertices = 1) out;

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
}