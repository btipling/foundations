
void main()
{
    vec3 f_V = normalize(f_camera_pos.xyz - fo_vert);
    vec3 f_N = normalize(fo_normals);
    vec3 f_R = reflect(-f_V, f_N);
    fo_frag_color = texture(f_cubemap, f_R);
}
