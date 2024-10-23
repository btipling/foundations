#version 460

layout (triangles) in;

in vec4 f_frag_color[];
out vec4 fo_frag_color_g;
layout (triangle_strip, max_vertices=3) out;

void main (void)
{
    for (int i=0; i < 3; i++)
    {
        gl_Position = gl_in[i].gl_Position;
        fo_frag_color_g = f_frag_color[i];
        EmitVertex();
    }
    EndPrimitive();
}