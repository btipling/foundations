
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


vec4 f_blinn_phong_lighting(Material f_mat, Light f_lights[10], uint num_lights, vec4 f_ambient_light) {
    num_lights = min(num_lights, 10u);

    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);

    vec4 rv = vec4(0.0, 0.0, 0.0, 1.0);
    
    uint i = 0;
    do {
        Light f_light = f_lights[i];
        vec3 f_L = normalize(f_light.direction.xyz);
        vec3 f_H = normalize(f_L + f_V).xyz;

        float cosTheta = dot(f_L, f_N);
        float cosPhi = dot(f_H, f_N);

        vec3 f_ambient = ((f_ambient_light * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
        vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);
        vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess * 4.0);

        rv = rv + vec4((f_ambient + f_diffuse + f_specular), 0.0);
        i += 1;
    } while (i < num_lights);
    return rv;
}

vec4 f_blinn_phong_lighting_no_mat(Light f_lights[10], uint num_lights, vec4 f_ambient_light, float f_mat_shininess) {
    num_lights = min(num_lights, 10u);

    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);

    vec4 rv = vec4(0.0, 0.0, 0.0, 1.0);
    
    uint i = 0;
    do {
        Light f_light = f_lights[i];
        vec3 f_L = normalize(f_light.direction.xyz);
        vec3 f_H = normalize(f_L + f_V).xyz;

        float cosTheta = dot(f_L, f_N);
        float cosPhi = dot(f_H, f_N);

        vec3 f_ambient = (f_ambient_light + f_light.ambient).xyz;
        vec3 f_diffuse = f_light.diffuse.xyz * max(cosTheta, 0.0);
        vec3 f_specular = f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat_shininess * 4.0);

        rv = rv + vec4((f_ambient + f_diffuse + f_specular), 0.0);
        i += 1;
    } while (i < num_lights);
    return rv;
}


vec4 f_blinn_phong_lighting_texture(vec4 f_tx_color, Light f_lights[10], uint num_lights, vec4 f_ambient_light, float f_mat_shininess) {
    num_lights = min(num_lights, 10u);

    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);

    vec4 rv = vec4(0.0, 0.0, 0.0, 1.0);
    
    uint i = 0;
    do {
        Light f_light = f_lights[i];
        vec3 f_L = normalize(f_light.direction.xyz);
        vec3 f_H = normalize(f_L + f_V).xyz;

        float cosTheta = dot(f_L, f_N);
        float cosPhi = dot(f_H, f_N);

        vec3 f_ambient = (f_ambient_light + f_light.ambient).xyz;
        vec3 f_diffuse = f_light.diffuse.xyz * max(cosTheta, 0.0);
        vec3 f_specular = f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat_shininess * 4.0);

        rv = rv + f_tx_color * vec4((f_ambient + f_diffuse), 0.0) + vec4(f_specular, 0);
        i += 1;
    } while (i < num_lights);
    return rv;
}

vec4 f_phong_lighting(Material f_mat, Light f_lights[10], uint num_lights, vec4 f_ambient_light) {
    num_lights = min(num_lights, 10u);
    
    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);

    vec4 rv = vec4(0.0, 0.0, 0.0, 1.0);

    uint i = 0;
    do {
        Light f_light = f_lights[i];
        vec3 f_L = normalize(f_light.direction.xyz);
        vec3 f_R = reflect(-f_L, f_N);

        float cosTheta = dot(f_L, f_N);
        float cosPhi = dot(f_V, f_R);

        vec3 f_ambient = ((f_ambient_light * f_mat.ambient) + (f_light.ambient * f_mat.ambient)).xyz;
        vec3 f_diffuse = f_light.diffuse.xyz * f_mat.diffuse.xyz * max(cosTheta, 0.0);
        vec3 f_specular = f_mat.specular.xyz * f_light.specular.xyz * pow(max(cosPhi, 0.0), f_mat.shininess);
    
        rv = rv + vec4((f_ambient + f_diffuse + f_specular), 0.0);
        i += 1;
    } while (i < num_lights);
    return rv;
}

