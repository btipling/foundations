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

layout (line_strip, max_vertices=2) out;

float f_s_len = 0.1;

void main (void)
{
    mat4 m_matrix = mat4(
        fo_t_column0[0],
        fo_t_column1[0],
        fo_t_column2[0],
        fo_t_column3[0]
    );
    vec3 f_op0 = fo_vert[0];
    vec3 f_op1 = fo_vert[1];
    vec3 f_op2 = fo_vert[2];

    vec3 f_ep0 = fo_vert[0] + fo_normal[0] * f_s_len;
    vec3 f_ep1 = fo_vert[1] + fo_normal[1] * f_s_len;
    vec3 f_ep2 = fo_vert[2] + fo_normal[2] * f_s_len;

    vec3 f_new_point_1 = (f_op0 + f_op1 + f_op2)/3.0;
    vec3 f_new_point_2 = (f_ep0 + f_ep1 + f_ep2)/3.0;

    gl_Position = f_mvp * m_matrix * vec4(f_new_point_1, 1.0);
    fo_vert_g = f_new_point_1;
    fo_light_g = fo_light[0];
    f_normal_g = fo_normal[0];
    fo_frag_color_g = f_frag_color[0];
    EmitVertex();

    gl_Position = f_mvp * m_matrix * vec4(f_new_point_2, 1.0);
    fo_vert_g = f_new_point_2;
    fo_light_g = fo_light[1];
    f_normal_g = fo_normal[1];
    fo_frag_color_g = f_frag_color[1];
    EmitVertex();

    EndPrimitive();
}