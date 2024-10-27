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
