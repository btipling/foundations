
uniform mat4 f_object_m;

void main()
{
    gl_Position = f_mvp * f_xup * f_object_m * vec4(f_position.xyz, 1.0);
    f_frag_color = f_color;
}
