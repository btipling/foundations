#version 460

layout (triangles) in;

//#include "src/foundations/shaders/camera.glsl"

in vec3 fo_normal[];
in vec3 fo_vert[];
in vec3 fo_light[];

out vec3 f_normal_g;
out vec3 fo_vert_g;
out vec3 fo_light_g;

in vec4 fo_t_column0[];
in vec4 fo_t_column1[];
in vec4 fo_t_column2[];
in vec4 fo_t_column3[];

layout (triangle_strip, max_vertices=3) out;

vec3 f_new_points_g[9];
float f_s_len = 0.01;

void f_set_putput_values(int f_i, int f_pin, vec3 f_norm_in)
{
    mat4 m_matrix = mat4(
        fo_t_column0[f_i],
        fo_t_column1[f_i],
        fo_t_column2[f_i],
        fo_t_column3[f_i]
    );
    gl_Position = f_mvp * m_matrix * vec4(f_new_points_g[f_pin], 1.0);
    f_normal_g = f_norm_in;
    fo_vert_g = f_new_points_g[f_pin];
    fo_light_g = fo_light[0];
}

void f_make_new_triangle(int f_i, int f_p1, int f_p2)
{
    vec3 f_c1 = normalize(f_new_points_g[f_p1] - f_new_points_g[3]);
    vec3 f_c2 = normalize(f_new_points_g[f_p2] - f_new_points_g[3]);
    vec3 f_nt_norm = cross(f_c1, f_c2);

    f_set_putput_values(f_i, f_p1, f_nt_norm);
    EmitVertex();
    f_set_putput_values(f_i, f_p2, f_nt_norm);
    EmitVertex();
    f_set_putput_values(f_i, 3, f_nt_norm);
    EmitVertex();
    EndPrimitive();
}

void main (void)
{
    vec3 f_sp0 = fo_vert[0] + fo_normal[0] * f_s_len;
    vec3 f_sp1 = fo_vert[1] + fo_normal[1] * f_s_len;
    vec3 f_sp2 = fo_vert[2] + fo_normal[2] * f_s_len;

    f_new_points_g[0] = fo_vert[0];
    f_new_points_g[1] = fo_vert[1];
    f_new_points_g[2] = fo_vert[2];
    f_new_points_g[3] = (f_sp0 + f_sp1 + f_sp2)/3.0;

    f_make_new_triangle(0, 0, 1);
    f_make_new_triangle(0, 1, 2);
    f_make_new_triangle(0, 2, 0);
}