in vec3 fo_light_dir;

vec4 f_blinn_phong_lighting_texture(vec4 f_tx_color, Light f_lights[10], uint num_lights, vec4 f_ambient_light, float f_mat_shininess) {
    num_lights = min(num_lights, 10u);

    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = normalize(fo_normal);

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


void main()
{
    Light f_ls[10];
    f_ls[0] = f_lights[0];
    f_ls[0].direction = vec4(fo_light_dir, 1.0);
    vec4 f_texture_color = texture(f_samp, f_tc);
    fo_frag_color = f_blinn_phong_lighting_texture(f_texture_color, f_ls, 1,  vec4(0.0, 0.0, 0.0, 1.0), 8.0);
}