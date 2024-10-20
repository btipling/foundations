#version 460
#extension GL_ARB_bindless_texture : require

//#include "src/foundations/shaders/camera.glsl"

uniform mat4 f_terrain_m;
layout(bindless_sampler) uniform sampler2D f_terrain_samp;

layout (quads, equal_spacing, ccw) in;
out vec2 f_tc_tes;

void main(void)
{
    vec4 f_tp = vec4(gl_TessCoord.x - 0.5, 0.0, gl_TessCoord.y - 0.5, 1.0);
    vec2 f_tc_out = vec2(gl_TessCoord.x, 1.0 - gl_TessCoord.y);
    f_tp.y += (texture(f_terrain_samp, f_tc_out).r) / 40.0;
    gl_Position = f_mvp * f_terrain_m * vec4(f_tp.y, -f_tp.z, f_tp.x, 1.0);
    f_tc_tes = f_tc_out;
}