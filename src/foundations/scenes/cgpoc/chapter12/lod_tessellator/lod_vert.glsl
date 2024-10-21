#version 460

//#include "src/foundations/shaders/vertex_outs.glsl"

uniform vec3 f_light_1_pos;
out vec4 f_lod_xup;

void main(void) { 
    
    mat4 f_lod_xup_m = mat4(
        0, 0, 1, 0,
        1, 0, 0,  0,
        0, 1, 0,  0,
        0, 0, 0,  1);

    vec2 f_patch_tex_coords[] = vec2[](vec2(0.0, 0.0), vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(1.0, 1.0));

    int f_x = gl_InstanceID % 128;
    int f_y = gl_InstanceID / 128;

    f_tc = vec2( (f_x + f_patch_tex_coords[gl_VertexID].x) / 128.0, (127 - f_y + f_patch_tex_coords[gl_VertexID].y) / 128.0);

    gl_Position = vec4(f_tc.x - 0.5, 0.0, (1.0 - f_tc.y) - 0.5, 1.0);
    f_lod_xup = f_lod_xup_m * gl_Position;
}