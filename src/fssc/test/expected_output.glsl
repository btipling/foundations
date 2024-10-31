#version 460 core

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

//#include "src/compiler/test/camera.glsl"
layout(std140, binding = 0) uniform CameraBuffer {
    mat4 f_mvp;
    mat4 v_matrix;
    vec4 f_camera_pos;
    vec4 f_global_ambient;
};


uniform mat4 f_model_transform;

//#include "src/compiler/test/lights.glsl"
struct Light {
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    vec4 location;
    vec4 direction;
    float cutoff;
    float exponent;
    float attenuation_constant;
    float attenuation_linear;
    float attenuation_quadratic;
    int light_kind;  // 0: direction, 1: positional, 2: spotlight
    float padding_1; // Explicit padding
    float padding_2; // Explicit padding
};

layout(std430, binding = 0) buffer MaterialBuffer {
    Material f_materials[];
};

layout(std430, binding = 1) buffer LightBuffer {
    Light f_lights[];
};

//#include "src/compiler/test/materials.glsl"
struct Material {
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
    float padding_1;
    float padding_2;
    float padding_3;
};

void main()
{
    mat4 f_transform = mat4(
        f_t_column0,
        f_t_column1,
        f_t_column2,
        f_t_column3
    );
    vec4 f_pos = f_mvp * f_transform * f_xup * vec4(f_position.xyz, 1.0);
    gl_Position = f_pos;
    f_tc = f_texture_coords;
    f_frag_color = f_i_color;
    fo_normal = f_normal;
}
