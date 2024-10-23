#version 460

layout (triangles) in;

in vec3 fo_normal[];
in vec3 fo_vert[];
in vec3 fo_light[];
in vec4 f_frag_color[];

out vec3 f_normal_g;
out vec3 fo_vert_g;
out vec3 fo_light_g;
out vec4 fo_frag_color_g;

layout (triangle_strip, max_vertices=3) out;

void main (void)
{
    for (int i=0; i < 3; i++)
    {
        gl_Position = gl_in[i].gl_Position;
        f_normal_g = fo_normal[i];
        fo_vert_g = fo_vert[i];
        fo_light_g = fo_light[i];
        fo_frag_color_g = f_frag_color[i];
        EmitVertex();
    }
    EndPrimitive();
}