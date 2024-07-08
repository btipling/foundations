#version 460 core
layout (location = 0) in vec3 f_position;
layout (location = 1) in vec4 f_color;

uniform mat4 f_transform;

out vec4 fo_color;

void main()
{
    vec4 pos = f_transform * vec4(f_position.xyz, 1.0);
    gl_Position = pos;
    fo_color = f_color;
}