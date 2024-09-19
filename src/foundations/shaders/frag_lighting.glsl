#version 460 core

in vec4 f_frag_color;
out vec4 fo_frag_color;

struct Material {
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
    float padding_1;
    float padding_2;
    float padding_3;
};

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

void main()
{
    Material f_m = f_materials[0];
    Light f_l = f_lights[0];
    fo_frag_color = f_m.specular + f_l.diffuse;
}