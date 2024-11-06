#version 460 
// #extension GL_ARB_bindless_texture : require

in vec2 f_tc;
out vec4 fo_frag_color;

void main()
{
    fo_frag_color = vec4(1.0, 0.0, 1.0, 1.0);
}
