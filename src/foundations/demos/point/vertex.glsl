#version 460 core

uniform float f_offset;

void main()
{
    gl_Position = vec4(f_offset, 0.0, 0.0, 1.0);
}