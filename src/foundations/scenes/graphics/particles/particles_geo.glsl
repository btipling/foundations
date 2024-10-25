#version 460

layout (points) in;

//#include "src/foundations/shaders/camera.glsl"


struct Particle {
    vec4 tr;
    vec4 color;
};

layout(std430, binding = 2) buffer ParticleBuffer {
    Particle f_particles[];
};

uniform int f_particles_data;


in vec3 fo_normal[];
in vec3 fo_vert[];
in vec3 fo_light[];
in vec4 f_frag_color[];
flat in int fo_instance_id[];

out vec3 f_normal_g;
out vec3 fo_vert_g;
out vec3 fo_light_g;
out vec4 fo_frag_color_g;

layout (triangle_strip, max_vertices=60) out;

void main (void)
{
    
    for (int i=0; i < f_particles_data; i++)
    {


        Particle f_cur_p = f_particles[fo_instance_id[0]];

        float seed = f_cur_p.color.w;
        float rx = fract(seed * 0.129898);
        float ry = fract(seed * 0.78233);
        
        // Now rx and ry are in 0-1 range
        vec2 offset = vec2(rx * 2.0 - 1.0, ry * 2.0 - 1.0); // convert to -1 to 1 range
        vec3 f_part_tr = f_cur_p.tr.xyz;
        f_part_tr.z = f_part_tr.z + rx;
        f_part_tr.y = f_part_tr.y + ry;

        mat4 f_p_rot = mat4(transpose(mat3(v_matrix)));
        float f_scale = f_cur_p.tr.w;
        vec4 f_p_color = vec4(f_cur_p.color.x, f_cur_p.color.y, f_cur_p.color.z, 1.0);
        mat4 f_p_translate = mat4(
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            f_part_tr.x, f_part_tr.y, f_part_tr.z, 1.0
        );
        mat4 f_p_scale = mat4(
            f_scale, 0.0, 0.0, 0.0,
            0.0, f_scale, 0.0, 0.0,
            0.0, 0.0, f_scale, 0.0,
            0.0, 0.0, 0.0, 1.0
        );
        vec3 p0 = vec3(-0.5, 0.0,-0.5);
        vec3 p1 = vec3(-0.5, 0.0, 0.5);
        vec3 p2 = vec3(0.5, 0.0, -0.5);
        vec3 p3 = vec3(0.5, 0.0, 0.5);
        mat4 m_matrix = f_p_translate * f_p_rot * f_p_scale;
        mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix)));
        vec3 emit_norm = normalize(f_norm_matrix * fo_normal[0]);

        f_normal_g = emit_norm;
        fo_vert_g = p0;
        fo_light_g = fo_light[0];
        fo_frag_color_g = f_p_color;
        gl_Position = f_mvp * m_matrix * vec4(fo_vert_g, 1.0);
        EmitVertex();

        f_normal_g = emit_norm;
        fo_vert_g = p1;
        fo_light_g = fo_light[0];
        fo_frag_color_g = f_p_color;
        gl_Position = f_mvp * m_matrix * vec4(fo_vert_g, 1.0);
        EmitVertex();
        
        f_normal_g = emit_norm;
        fo_vert_g = p2;
        fo_light_g = fo_light[0];
        fo_frag_color_g = f_p_color;
        gl_Position = f_mvp * m_matrix * vec4(fo_vert_g, 1.0);
        EmitVertex();

        f_normal_g = emit_norm;
        fo_vert_g = p3;
        fo_light_g = fo_light[0];
        fo_frag_color_g = f_p_color;
        gl_Position = f_mvp * m_matrix * vec4(fo_vert_g, 1.0);
        EmitVertex();

        EndPrimitive();
    }
}