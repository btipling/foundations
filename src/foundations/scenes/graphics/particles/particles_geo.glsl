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

layout (triangle_strip, max_vertices=3) out;

void main (void)
{
    mat4 face_cam = mat4(transpose(mat3(v_matrix)));

    vec3 p0 = vec3(0.0, 0.0, 0.0);
    vec3 p1 = vec3(0.0, 0.0, 1.0);
    vec3 p2 = vec3(1.0, 0.0, 0.0);
    mat4 m_matrix = face_cam;
    mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix)));
    vec3 emit_norm = normalize(f_norm_matrix * fo_normal[0]);

    f_normal_g = emit_norm;
    fo_vert_g = p0;
    fo_light_g = fo_light[0];
    fo_frag_color_g = f_frag_color[0];
    gl_Position = f_mvp * m_matrix * vec4(fo_vert_g, 1.0);
    EmitVertex();

    f_normal_g = emit_norm;
    fo_vert_g = p1;
    fo_light_g = fo_light[0];
    fo_frag_color_g = f_frag_color[0];
    gl_Position = f_mvp * m_matrix * vec4(fo_vert_g, 1.0);
    EmitVertex();
    
    f_normal_g = emit_norm;
    fo_vert_g = p2;
    fo_light_g = fo_light[0];
    fo_frag_color_g = f_frag_color[0];
    gl_Position = f_mvp * m_matrix * vec4(fo_vert_g, 1.0);
    EmitVertex();

    EndPrimitive();
}