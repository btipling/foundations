
in vec4 f_frag_color;
in vec3 fo_normals;
in vec3 fo_vert;
in vec3 fo_lightdir;


void main()
{


    Material f_m = f_materials[0];
    Light f_l = f_lights[0];

    vec3 f_L = normalize(fo_lightdir);
    vec3 f_V = normalize(-v_matrix[3].xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);
    vec3 f_R = reflect(-f_L, f_N);

    float cosTheta = dot(f_L, f_N);
    float cosPhi = dot(f_V, f_R);

    vec4 f_global_ambient = vec4(0.7, 0.7, 0.7, 1.0);
    vec3 f_ambient = ((f_global_ambient * f_m.ambient) + (f_l.ambient * f_m.ambient)).xyz;
    vec3 f_diffuse = f_l.diffuse.xyz * f_m.diffuse.xyz * max(dot(f_N, f_L), 0.0);
    vec3 f_specular = f_m.specular.xyz * f_l.specular.xyz * pow(max(dot(f_R, f_V), 0.0), f_m.shininess);

    fo_frag_color = vec4((f_ambient + f_diffuse + f_specular), 1.0);
}
