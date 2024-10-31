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


//#include "src/foundations/shaders/camera.glsl"

//#include "src/foundations/shaders/vertex_outs.glsl"

out vec3 fo_light;
out vec3 fo_pos;

uniform mat4 f_sky_rot;
uniform float f_sky_dep;

void main()
{
    mat4 f_cubemap_t = mat4(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        f_camera_pos[0], f_camera_pos[1], f_camera_pos[2], 1
    );
    mat4 f_transform = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    vec4 f_main_pos = f_cubemap_t * f_transform * vec4(f_position.xyz, 1.0);
    vec4 f_pos = vec4(f_position.xyz, 1.0);

    fo_pos = (f_sky_rot * f_pos).xyz;
    fo_pos.y = f_sky_dep;


    fo_normal = f_normal;
    fo_vert = f_position.xyz;
    gl_Position = f_mvp *  f_main_pos;
    f_frag_color = f_i_color;
}