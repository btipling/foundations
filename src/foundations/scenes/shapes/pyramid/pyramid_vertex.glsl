uniform mat4 f_transform;
uniform float f_pinhole;

out vec4 f_frag_color;
out vec3 fo_normals;

void main()
{
    vec4 pos = f_transform * vec4(f_position.xyz, 1.0);
    if (f_pinhole > 0 ) {
        pos.x = pos.x / f_pinhole;
        pos.y = pos.y / f_pinhole;
        pos.z = f_pinhole;
    }
    gl_Position = pos;
    f_frag_color = f_color;
    fo_normals = f_normals;
}