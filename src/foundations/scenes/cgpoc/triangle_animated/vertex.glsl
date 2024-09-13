#version 460 core

uniform float f_offset;
uniform mat4 f_transform;

void main()
{
    vec4 f_positions[3];
    f_positions[0] = vec4(0.25, -0.25, 0.0, 1.0);
    f_positions[1] = vec4(-0.25, -0.25, 0.0, 1.0);
    f_positions[2] = vec4(0.0, 0.25, 0.0, 1.0);
    vec4 pos = f_positions[gl_VertexID];
    pos = vec4(pos.x += f_offset, pos.yzw);
    pos = f_transform * pos;
    gl_Position = pos;
}