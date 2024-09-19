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

layout(std430, binding = 0) buffer MaterialBuffer {
    Material f_materials[];
};

void main()
{
    Material f_m = f_materials[0];
    fo_frag_color = f_m.specular;
} 