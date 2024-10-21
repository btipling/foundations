#version 460 core
#extension GL_ARB_bindless_texture : require
layout (location = 0) in vec3 f_position;
layout (location = 1) in vec4 f_color;
layout (location = 2) in vec3 f_normal;
layout (location = 3) in vec2 f_texture_coords;
layout (location = 4) in vec4 f_tangent;
layout (location = 5) in vec4 f_t_column0;
layout (location = 6) in vec4 f_t_column1;
layout (location = 7) in vec4 f_t_column2;
layout (location = 8) in vec4 f_t_column3;
layout (location = 9) in vec4 f_i_color;

/*******************************************/
/*******************************************/
/*******************************************/
/*******************  EARTH VERT ***********/
/*******************************************/
/*******************************************/
/*******************************************/

//#include "src/foundations/shaders/camera.glsl"

uniform mat4 f_model_transform;


//#include "src/foundations/shaders/vertex_outs.glsl"

layout(bindless_sampler) uniform sampler2D f_earth_heightmap;

uniform vec3 f_earth_light_pos;

void main()
{
    mat4 m_matrix = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    mat3 f_norm_matrix = transpose(inverse(mat3(m_matrix)));
    float h_pos = texture(f_earth_heightmap, f_texture_coords).r * 0.025;
    vec4 f_pos = vec4(f_position.xyz, 1.0) + vec4(f_normal * h_pos, 1.0);
    vec4 f_main_pos = m_matrix * f_pos;

    fo_vert = f_main_pos.xyz;
    fo_normal = normalize(f_norm_matrix * f_normal);
    f_tc = f_texture_coords;
    f_frag_color = vec4(h_pos, 0.0, 0.0, 2.0);
    fo_tangent = m_matrix * vec4(f_tangent.xyz, 0);
    fo_tangent.w = f_tangent.w;
    fo_lightdir = (vec4(f_earth_light_pos, 0)).xyz;
    gl_Position = f_mvp * f_main_pos;
}