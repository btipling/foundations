#version 460

layout(local_size_x = 1) in;
layout(binding=1, rgba8) uniform image2D f_texture;

uniform float f_camera_pos_z = 5.0;


layout(std140, binding = 3) uniform SceneData {
    vec4 f_sphere_radius;
    vec4 f_sphere_position;
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

Collision f_intersect_sphere_object(Ray f_ray) {
    vec3 f_p = f_ray.start - f_sphere_position.xyz;
    float f_qa = dot(f_ray.dir, f_ray.dir);
    float f_qb = dot(2.0 * f_ray.dir, f_p);
    float f_qc = dot(f_p, f_p) - f_sphere_radius.x * f_sphere_radius.x;
    
    float f_qd = f_qb * f_qb - 4 * f_qa * f_qc;

    Collision f_c;
    f_c.object_index = 1;
    f_c.inside = false;
    if (f_qd < 0.0) {
        f_c.t = -1.0;
        return f_c;
    }
    
    float f_sqrt_qd = sqrt(f_qd);
    float f_den = 2.0 * f_qa;
    float f_t1 = (-f_qb + f_sqrt_qd) / f_den;
    float f_t2 = (-f_qb - f_sqrt_qd) / f_den;
    float f_t_near = min(f_t1, f_t2);
    float f_t_far = max(f_t1, f_t2);

    if (f_t_far < 0.0) {
        f_c.t = -1.0;
        return f_c;
    }

    f_c.t = f_t_near;
    if (f_t_near < 0.0) {
        f_c.t = f_t_far;
        f_c.inside = true;
    }
    f_c.p = f_ray.start + f_c.t * f_ray.dir;
    f_c.n = normalize(f_c.p - f_sphere_position.xyz);

    if (f_c.inside) {
        f_c.n *= -1.0;
    }

    return f_c;
}

Collision f_get_closest_collision(Ray f_ray) {
    Collision f_c_col, f_sphere_c;
    f_c_col.object_index = -1;

    f_sphere_c = f_intersect_sphere_object(f_ray);

    if (f_sphere_c.t > 0) {
        f_c_col = f_sphere_c;
    }

    return f_c_col;
}

vec3 f_ray_trace(Ray f_ray) {
    Collision f_c = f_get_closest_collision(f_ray);
    if (f_c.object_index == -1) return vec3(0.0);
    if (f_c.object_index == 1) return f_sphere_color.xyz;
    return vec3(1.0, 0.0, 1.0);
}

void main()
{
    int f_width = int(gl_NumWorkGroups.x);
    int f_height = int(gl_NumWorkGroups.y);
    ivec2 f_texel = ivec2(gl_GlobalInvocationID.xy);
    float f_x_texel = 2.0 * f_texel.x / f_width - 1.0;
    float f_y_texel = 2.0 * f_texel.y / f_height - 1.0;
    Ray f_world_ray;
    f_world_ray.start = vec3(0.0, 0.0, f_camera_pos_z);
    vec4 f_world_ray_end = vec4(f_x_texel, f_y_texel, f_camera_pos_z - 1.0, 1.0);
    f_world_ray.dir = normalize(f_world_ray_end.xyz - f_world_ray.start);
    vec4 f_output_color = vec4(f_ray_trace(f_world_ray), 1.0);
    imageStore(f_texture, f_texel, f_output_color);
}