
vec4 f_phong_lighting(Material f_mat, Light f_lights[10], uint num_lights, vec4 f_ambient_light) {
    num_lights = min(num_lights, 10u);
    
    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = normalize(fo_normal);

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



void main()
{
    Material f_m = f_materials[0];
    Light f_l = f_lights[0];

    fo_frag_color = f_phong_lighting(f_m, f_l);
}
