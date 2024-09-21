
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

vec4 f_blinn_phong_lighting(Material f_mat, Light f_light) {
    
    vec3 f_L = normalize(fo_lightdir);
    vec3 f_V = normalize(-v_matrix[3].xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);
    vec3 f_H = normalize(f_L + f_V).xyz;

    float cosTheta = dot(f_L, f_N);
    float cosPhi = dot(f_H, f_N);

    vec4 f_global_ambient = vec4(0.7, 0.7, 0.7, 1.0);
    vec3 f_ambient = ((f_global_ambient * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
    vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);
    vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess * 4.0);

    return vec4((f_ambient + f_diffuse + f_specular), 1.0);
}

vec4 f_phong_lighting(Material f_mat, Light f_light) {

    vec3 f_L = normalize(fo_lightdir);
    vec3 f_V = normalize(-v_matrix[3].xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);
    vec3 f_R = reflect(-f_L, f_N);

    float cosTheta = dot(f_L, f_N);
    float cosPhi = dot(f_V, f_R);

    vec4 f_global_ambient = vec4(0.7, 0.7, 0.7, 1.0);
    vec3 f_ambient = ((f_global_ambient * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
    vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);
    vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess);
    
    return vec4((f_ambient + f_diffuse + f_specular), 1.0);
}

