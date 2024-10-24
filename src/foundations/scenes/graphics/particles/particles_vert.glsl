#version 460 core
layout (location = 0) in vec3 f_position;
layout (location = 1) in vec4 f_color;
layout (location = 2) in vec3 f_normal;
layout (location = 3) in vec2 f_texture_coords;
layout (location = 4) in vec4 f_tangent;
layout (location = 5) in vec4 f_t_column0;
layout (location = 6) in vec4 f_t_column1;
layout (location = 7) in vec4 f_t_column2;
layout (location = 8) in vec4 f_t_column3;
layout (location = 9) in vec4 f_i_color;

//#include "src/foundations/shaders/light.glsl"

//#include "src/foundations/shaders/camera.glsl"

//#include "src/foundations/shaders/vertex_outs.glsl"

out vec4 fo_t_column0;
out vec4 fo_t_column1;
out vec4 fo_t_column2;
out vec4 fo_t_column3;

out vec3 fo_light;

void main()
{
    fo_t_column0 = f_t_column0;
    fo_t_column1 = f_t_column1;
    fo_t_column2 = f_t_column2;
    fo_t_column3 = f_t_column3;
    Light f_light = f_lights[0];

    vec4 f_main_pos = vec4(f_position.xyz, 1.0);
    fo_light = f_light.direction.xyz;
    fo_vert = f_main_pos.xyz;
    fo_normal = f_normal;
    f_tc = f_texture_coords;
    f_frag_color = f_i_color;
    gl_Position = f_main_pos;
}