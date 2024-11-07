#version 460

layout(local_size_x = 1) in;
layout(binding=1, rgba8) uniform image2D f_texture;

uniform float f_camera_pos_z = 5.0;

layout(std140) uniform SceneData {
    float f_sphere_radius;
    vec3 f_sphere_position;
    vec4 f_sphere_color;
    vec4 f_box_position;
    vec4 f_box_dims;
    vec4 f_box_color;
    vec4 f_box_rotation;
};

struct Ray {
    vec3 start;
    vec3 dir;
};

struct Collision {
    float t;
    vec3 p;
    vec3 n;
    bool inside;
    int object_index;
};

Collision f_get_closest_collision(Ray f_ray) {
    Collision f_c_col;
    f_c_col.object_index = -1;
    return f_c_col;
}

vec3 f_ray_trace(Ray f_ray) {
    Collision f_c = f_get_closest_collision(f_ray);
    if (f_c.object_index == -1) return vec3(0.0);
    return f_sphere_color.xyz;
}

void main()
{
    Ray f_world_ray;
    f_world_ray.start = vec3(0.0, 0.0, f_camera_pos_z);
    vec4 f_output_color = vec4(f_ray_trace(f_world_ray), 1.0);
    ivec2 f_texel = ivec2(gl_GlobalInvocationID.xy);
    imageStore(f_texture, f_texel, f_output_color);
}