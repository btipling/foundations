
mat4 f_cubemap_xup = (mat4(
    vec4(0, 1, 0, 0),
    vec4(0, 0, 1, 0),
    vec4(1, 0, 0, 0),
    vec4(0, 0, 0, 1)
));


void main()
{
    vec3 f_V = normalize((f_cubemap_xup * f_camera_pos).xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);
    
    vec3 f_R = -reflect(f_V, f_N);
    fo_frag_color = texture(f_cubemap, f_R);
}
