#version 460

//#include "src/foundations/shaders/camera.glsl"

layout(vertices = 1) out;

uniform mat4 f_terrain_m;

in vec2 f_tc[];
in vec4 f_lod_xup[];
out vec2 f_tc_tcs[];


void main(void)
{
    float f_sub_divs = 100.0;
    if (gl_InvocationID == 0) {
        float f_distance = distance(f_terrain_m * f_lod_xup[gl_InvocationID], f_camera_pos);
        float f_TL = max(1.0, min(32.0, f_sub_divs / f_distance));
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