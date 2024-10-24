#version 460

layout (triangles) in;

//#include "src/foundations/shaders/camera.glsl"

in vec3 fo_normal[];
in vec3 fo_vert[];
in vec3 fo_light[];
in vec4 f_frag_color[];

in vec4 fo_t_column0[];
in vec4 fo_t_column1[];
in vec4 fo_t_column2[];
in vec4 fo_t_column3[];

out vec3 f_normal_g;
out vec3 fo_vert_g;
out vec3 fo_light_g;
out vec4 fo_frag_color_g;

layout (triangle_strip, max_vertices=3) out;

void main (void)
{
    for (int i=0; i < 3; i++)
    {
        mat4 m_matrix = mat4(
            fo_t_column0[i],
            fo_t_column1[i],
            fo_t_column2[i],
            fo_t_column3[i]
        );
        mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix)));
        f_normal_g = normalize(f_norm_matrix * fo_normal[i]);
        fo_vert_g = fo_vert[i];
        fo_light_g = fo_light[i];
        fo_frag_color_g = f_frag_color[i];
        gl_Position = f_mvp * m_matrix * vec4(fo_vert[i], 1.0);
        EmitVertex();
    }
    EndPrimitive();
}