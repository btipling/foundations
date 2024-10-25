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

