#version 460 
#extension GL_ARB_bindless_texture : require

in vec2 f_tc;
out vec4 fo_frag_color;

layout(bindless_sampler) uniform sampler2D f_texture;

void main()
{
    fo_frag_color = texture(f_texture, f_tc);
}
