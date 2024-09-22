
uniform mat4 f_reflection_transform;

void main()
{
    mat4 f_world_transform = f_reflection_transform;
    vec4 f_pos = f_mvp * f_world_transform * vec4(f_position.xyz, 1.0);
    gl_Position = f_pos;
    f_frag_color = f_color;
    fo_normals = f_normals;
}