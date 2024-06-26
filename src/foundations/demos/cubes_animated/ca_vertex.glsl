#version 460 core
layout (location = 0) in vec3 f_position;
layout (location = 1) in vec4 f_color;


uniform mat4 f_transform;
uniform float f_pinhole;

out vec4 fo_color;

void main()
{
    vec4 pos = f_transform * vec4(f_position.xyz, 1.0);
    if (f_pinhole > 0 ) {
        pos.x = pos.x / f_pinhole;
        pos.y = pos.y / f_pinhole;
        pos.z = f_pinhole;
    }
    gl_Position = pos;
    fo_color = f_color;
}