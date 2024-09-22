uniform vec2 f_rotating_point;

void main()
{
    gl_Position = vec4(f_rotating_point.xy, 0.0, 1.0);
    f_frag_color = vec4(0.0, 0.0, 1.0, 1.0);
}