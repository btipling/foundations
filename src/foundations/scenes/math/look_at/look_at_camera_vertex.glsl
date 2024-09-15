#version 460 core
layout (location = 0) in vec3 f_position;
layout (location = 1) in vec4 f_color;
layout (location = 2) in vec3 f_normals;
layout (location = 3) in vec2 f_texture_coords;

uniform mat4 f_mvp;
uniform mat4 f_camera_transform;

out vec4 fo_color;
out vec3 fo_normals;

void main()
{
    vec4 pos = f_mvp * f_camera_transform * vec4(f_position.xyz, 1.0);
    gl_Position = pos;
    fo_color = f_color;
    fo_normals = f_normals * 0.5 + 0.5;
}