#version 460 core
layout (location = 0) in vec3 f_position;
layout (location = 1) in vec4 f_color;
layout (location = 2) in vec3 f_normals;

uniform mat4 f_mvp;
uniform mat4 f_reflection_transform;

out vec4 fo_color;
out vec3 fo_normals;

void main()
{
    mat4 f_world_transform = f_reflection_transform;
    vec4 f_pos = f_mvp * f_world_transform * vec4(f_position.xyz, 1.0);
    gl_Position = f_pos;
    fo_color = f_color;
    fo_normals = normalize(transpose(inverse(mat3(f_reflection_transform))) * f_normals);
}