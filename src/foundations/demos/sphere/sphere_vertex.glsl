#version 460 core
layout (location = 0) in vec3 f_position;
layout (location = 1) in vec4 f_color;

uniform mat4 f_transform;
uniform mat4 f_color_transform;

out vec4 fo_color;

void main()
{
    vec4 pos = f_transform * vec4(f_position.xyz, 1.0);
    gl_Position = pos;
    vec4 out_color = f_color_transform * vec4(pos.xyz, 1.0);
    fo_color = vec4(out_color.xyz * 0.5 + 0.25, 1.0);
}