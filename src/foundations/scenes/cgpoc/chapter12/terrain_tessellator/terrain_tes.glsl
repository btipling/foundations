#version 460
#extension GL_ARB_bindless_texture : require

//#include "src/foundations/shaders/camera.glsl"

uniform mat4 f_terrain_m;
layout(bindless_sampler) uniform sampler2D f_terrain_samp;

layout (quads, equal_spacing, ccw) in;
in vec2 f_tc_tcs[];
out vec2 f_tc_tes;

void main(void)
{
    vec2 f_tc_out = vec2(f_tc_tcs[0].x + (gl_TessCoord.x) / 64.0, f_tc_tcs[0].y + (1.0 - gl_TessCoord.y)/ 64.0);
    vec4 f_tp = vec4(gl_in[0].gl_Position.x + gl_TessCoord.x / 64.0, 0.0,
                     gl_in[0].gl_Position.z + gl_TessCoord.y / 64.0, 1.0);
    
    f_tp.y += (texture(f_terrain_samp, f_tc_out).r) / 40.0;
    gl_Position = f_mvp * f_terrain_m * vec4(-f_tp.y, -f_tp.z, f_tp.x, 1.0);
    f_tc_tes = f_tc_out;
}