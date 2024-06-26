#version 460 core
layout (location = 0) in vec3 f_position;
layout (location = 1) in vec4 f_color;


uniform mat4 f_transform;

out vec4 fo_color;

void main()
{
    gl_Position = f_transform * vec4(f_position.xyz, 1.0);
    fo_color = f_color;
}