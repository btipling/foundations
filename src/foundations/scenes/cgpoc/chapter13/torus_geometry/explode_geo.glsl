#version 460

layout (triangles) in;

//#include "src/foundations/shaders/camera.glsl"

in vec3 fo_normal[];
in vec3 fo_vert[];
in vec3 fo_light[];
in vec4 f_frag_color[];

out vec3 f_normal_g;
out vec3 fo_vert_g;
out vec3 fo_light_g;
out vec4 fo_frag_color_g;

in vec4 fo_t_column0[];
in vec4 fo_t_column1[];
in vec4 fo_t_column2[];
in vec4 fo_t_column3[];

layout (triangle_strip, max_vertices=3) out;

void main (void)
{
    vec4 f_triangle_normal = vec4((fo_normal[0] + fo_normal[1] + fo_normal[2]/3.0), 1.0);
    for (int i=0; i < 3; i++)
    {
        mat4 m_matrix = mat4(
            fo_t_column0[i],
            fo_t_column1[i],
            fo_t_column2[i],
            fo_t_column3[i]
        );
        gl_Position = f_mvp * m_matrix * (vec4(fo_vert[i], 1.0) + normalize(f_triangle_normal) * 0.4);
        f_normal_g = fo_normal[i];
        fo_vert_g = fo_vert[i];
        fo_light_g = fo_light[i];
        fo_frag_color_g = f_frag_color[i];
        EmitVertex();
    }
    EndPrimitive();
}