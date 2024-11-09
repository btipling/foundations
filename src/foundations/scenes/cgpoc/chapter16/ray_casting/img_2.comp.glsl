#version 460

layout(local_size_x = 1) in;
layout(binding=1, rgba8) uniform image2D f_texture;

uniform float f_camera_pos_z = 5.0;
uniform int f_scene_index = 1;
uniform int f_light_index = 0;
uniform int f_mat_index = 0;

layout(std140, binding = 0) uniform CameraBuffer {
    mat4 f_mvp;
    mat4 v_matrix;
    vec4 f_camera_pos;
    vec4 f_global_ambient;
    mat4 f_shadow_view_m;
};

struct Material {
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
    float padding_1;
    float padding_2;
    float padding_3;
};

layout(std430, binding = 0) buffer MaterialBuffer {
    Material f_materials[];
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
    int light_kind; 
    float padding_1;
    float padding_2;
};

layout(std430, binding = 1) buffer LightBuffer {
    Light f_lights[];
};

struct SceneData {
    vec4 sphere_radius;
    vec4 sphere_position;
    vec4 sphere_color;
    vec4 box_position;
    vec4 box_dims;
    vec4 box_color;
    vec4 box_rotation;
};

layout(std140, binding = 3) uniform SceneBuffer {
    SceneData f_scene_data[2];
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

Collision f_intersect_box_object(Ray f_ray) {
    SceneData f_sd = f_scene_data[f_scene_index];
    vec3 f_box_min = f_sd.box_position.xyz - (f_sd.box_dims.xyz / 2.0);
    vec3 f_box_max = f_sd.box_position.xyz + (f_sd.box_dims.xyz / 2.0);
    vec3 f_t_min = (f_box_min.xyz - f_ray.start) / f_ray.dir;
    vec3 f_t_max = (f_box_max.xyz - f_ray.start) / f_ray.dir;

    vec3 f_t_min_dist = min(f_t_min, f_t_max);
    vec3 f_t_max_dist = max(f_t_min, f_t_max);

    float f_t_near = max(max(f_t_min_dist.x, f_t_min_dist.y), f_t_min_dist.z);
    float f_t_far = min(min(f_t_max_dist.x, f_t_max_dist.y), f_t_max_dist.z);

    Collision f_c;
    f_c.object_index = 2;
    f_c.t = f_t_near;
    f_c.inside = false;

    if (f_t_near >= f_t_far || f_t_far <= 0.0) {
        f_c.t = -1.0;
        return f_c;
    }
    float f_intersect_distance = f_t_near;
    vec3 f_plane_intersect_distances = f_t_min_dist;

    if (f_t_near < 0.0) {
        f_c.t = f_t_far;
        f_intersect_distance = f_t_far;
        f_plane_intersect_distances = f_t_max_dist;
        f_c.inside = true;
    }

    int f_face_index = 0;
    if (f_intersect_distance == f_plane_intersect_distances.y) {
        f_face_index = 1;
    } else if (f_intersect_distance == f_plane_intersect_distances.z) {
        f_face_index = 2;
    }

    f_c.n = vec3(0.0);
    f_c.n[f_face_index] = 1.0;

    if (f_ray.dir[f_face_index] > 0.0) {
        f_c.n *= -1.0;
    }

    f_c.p = f_ray.start + f_c.t * f_ray.dir;
    return f_c;
}

Collision f_intersect_sphere_object(Ray f_ray) {
    SceneData f_sd = f_scene_data[f_scene_index];
    vec3 f_p = f_ray.start - f_sd.sphere_position.xyz;
    float f_qa = dot(f_ray.dir, f_ray.dir);
    float f_qb = dot(2.0 * f_ray.dir, f_p);
    float f_qc = dot(f_p, f_p) - f_sd.sphere_radius.x * f_sd.sphere_radius.x;
    
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
    f_c.n = normalize(f_c.p - f_sd.sphere_position.xyz);

    if (f_c.inside) {
        f_c.n *= -1.0;
    }

    return f_c;
}

Collision f_get_closest_collision(Ray f_ray) {
    Collision f_c_col, f_sphere_c, f_box_c;
    f_c_col.object_index = -1;

    f_sphere_c = f_intersect_sphere_object(f_ray);
    f_box_c = f_intersect_box_object(f_ray);

    if ((f_sphere_c.t > 0) && ((f_sphere_c.t < f_box_c.t) || (f_box_c.t < 0))) {
        f_c_col = f_sphere_c;
    }

    if ((f_box_c.t > 0) && ((f_box_c.t < f_sphere_c.t) || (f_sphere_c.t < 0))) {
        f_c_col = f_box_c;
    }

    return f_c_col;
}

vec3 f_ray_trace(Ray f_ray) {
    SceneData f_sd = f_scene_data[f_scene_index];
    Collision f_c = f_get_closest_collision(f_ray);
    if (f_c.object_index == -1) return vec3(0.0);
    if (f_c.object_index == 1) return f_sd.sphere_color.xyz;
    if (f_c.object_index == 2) return f_sd.box_color.xyz;
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