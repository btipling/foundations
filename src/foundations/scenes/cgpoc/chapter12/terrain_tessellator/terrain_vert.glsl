#version 460

//#include "src/foundations/shaders/vertex_outs.glsl"

uniform vec3 f_light_1_pos;

void main(void) { 
    vec2 f_patch_tex_coords[] = vec2[](vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(1.0, 1.0));

    int f_x = gl_InstanceID % 64;
    int f_y = gl_InstanceID / 64;

    f_tc = vec2( (f_x + f_patch_tex_coords[gl_VertexID].x) / 64.0, (63 - f_y + f_patch_tex_coords[gl_VertexID]) / 64.0);

    gl_Position = vec4(f_tc.x - 0.5, 0.0, (1.0 - f_tc.y) - 0.5, 1.0);
}