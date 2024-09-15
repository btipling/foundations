out vec4 f_frag_color;

void main()
{
    gl_Position = vec4(f_position.xyz, 1.0);
    f_frag_color = f_color;
}