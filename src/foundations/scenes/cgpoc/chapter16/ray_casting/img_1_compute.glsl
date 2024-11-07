#version 460

layout(local_size_x = 1) in;
layout(binding=1, rgba8) uniform image2D f_texture;

layout(std140) uniform SceneData {
    float f_sphere_radius;
    vec3 f_sphere_position;
    vec4 f_sphere_color;
    vec4 f_box_position;
    vec4 f_box_dims;
    vec4 f_box_color;
    vec4 f_box_rotation;
};

vec3 f_ray_trace() {
    return f_box_color.xyz;
}

void main()
{
    vec4 f_output_color = vec4(f_ray_trace(), 1.0);
    ivec2 f_texel = ivec2(gl_GlobalInvocationID.xy);
    imageStore(f_texture, f_texel, f_output_color);
}