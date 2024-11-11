#version 460

layout(local_size_x = 1) in;
layout(binding=1, rgba8) uniform image2D f_texture;
layout(binding=2) uniform sampler2D f_box_tex;
layout(binding=3) uniform sampler2D f_sphere_tex;

layout(binding=4) uniform sampler2D f_xp_tex;
layout(binding=5) uniform sampler2D f_xn_tex;
layout(binding=6) uniform sampler2D f_yn_tex;
layout(binding=7) uniform sampler2D f_yp_tex;
layout(binding=8) uniform sampler2D f_zp_tex;
layout(binding=9) uniform sampler2D f_zn_tex;

uniform int f_scene_index = 6;
uniform int f_light_index = 6;
uniform int f_mat_index = 0;
uniform float f_pi = 3.1415926535;

vec3 f_plane_pos = vec3(0, 2.5, -2.0);
float f_plane_width = 12.0;
float f_plane_depth = 8.0;
float f_plane_x_rot = 0.0;
float f_plane_y_rot = 0.0;
float f_plane_z_rot = 0.0;

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
    vec4 camera_position;
    vec4 camera_direction;
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
    vec2 tc;
    int face_index;
};


mat4 f_translate(vec3 pos) {	
    return mat4(
        1.0,        0.0,        0.0,        0.0,
        0.0,        1.0,        0.0,        0.0,
        0.0,        0.0,        1.0,        0.0,
        pos.x,      pos.y,      pos.z,      1.0
    );
}
mat4 f_rot_x(float rad) {	
    return mat4(
        1.0,        0.0,        0.0,        0.0,
        0.0,        cos(rad),   sin(rad),   0.0,
        0.0,        -sin(rad),  cos(rad),   0.0,
        0.0,        0.0,        0.0,        1.0
    );
}
mat4 f_rot_y(float rad) {	
    return mat4(
        cos(rad),   0.0,        -sin(rad),  0.0,
        0.0,        1.0,        0.0,        0.0,
        sin(rad),   0.0,        cos(rad),   0.0,
        0.0,        0.0,        0.0,        1.0
    );
}
mat4 f_rot_z(float rad) {	
    return mat4(
        cos(rad),   sin(rad),   0.0,        0.0,
        -sin(rad),  cos(rad),   0.0,        0.0,
        0.0,        0.0,        1.0,        0.0,
        0.0,        0.0,        0.0,        1.0
    );
}


Collision f_intersect_box_object(Ray f_ray) {
    SceneData f_sd = f_scene_data[f_scene_index];

    mat4 m = f_translate(f_sd.box_position.xyz);
    mat4 r = f_rot_y(f_sd.box_rotation.y);
    r *= f_rot_x(f_sd.box_rotation.x);
    r *= f_rot_z(f_sd.box_rotation.z);
    m *= r;
    mat4 mi = inverse(m);
    mat4 ri = inverse(r);

    vec3 f_ray_start = (mi * vec4(f_ray.start, 1.0)).xyz;
    vec3 f_ray_dir = (ri * vec4(f_ray.dir, 1.0)).xyz;

    vec3 f_box_min = f_sd.box_dims.xyz * 0.5;
    vec3 f_box_max = f_box_min * -1;
    vec3 f_t_min = (f_box_min.xyz - f_ray_start) / f_ray_dir;
    vec3 f_t_max = (f_box_max.xyz - f_ray_start) / f_ray_dir;

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

    if (f_ray_dir[f_face_index] > 0.0) {
        f_c.n *= -1.0;
    }
    f_c.n = normalize(transpose(inverse(mat3(r))) * f_c.n);


    f_c.p = f_ray.start + f_c.t * f_ray.dir;


    vec3 f_cp = (mi * vec4(f_c.p, 1.0)).xyz;
    
    float f_total_width = f_box_max.x - f_box_min.x;
    float f_total_height = f_box_max.y - f_box_min.y;
    float f_total_depth = f_box_max.z - f_box_min.z;
    float f_max_dim = max(max(f_total_width, f_total_height), f_total_depth);

    float f_ray_strike_x = (f_cp.x + f_total_width/2.0)/f_max_dim;
    float f_ray_strike_y = (f_cp.y + f_total_height/2.0)/f_max_dim;
    float f_ray_strike_z = (f_cp.z + f_total_depth/2.0)/f_max_dim;

    if (f_face_index == 0) {
        f_c.tc = vec2(f_ray_strike_z, f_ray_strike_y);
    } else if (f_face_index == 1) {
        f_c.tc = vec2(f_ray_strike_z, f_ray_strike_x);
    } else {
        f_c.tc = vec2(f_ray_strike_y, f_ray_strike_x);
    }

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

    f_c.tc.x = 0.5 + atan(-f_c.n.z, f_c.n.x) / (2.0 * f_pi);
    f_c.tc.y = 0.5 - asin(-f_c.n.y) / f_pi;

    return f_c;
}

Collision f_intersect_sky_box_object(Ray f_ray) {
    vec3 f_sky_box_min = vec3(-20, -20, -20);
    vec3 f_sky_box_max = vec3( 20,  20,  20);
    vec3 f_sky_box_color = vec3(1.0, 1.0, 1.0);

    vec3 f_t_min = (f_sky_box_min - f_ray.start) / f_ray.dir;
	vec3 f_t_max = (f_sky_box_max - f_ray.start) / f_ray.dir;
	vec3 f_t_min_dist = min(f_t_min, f_t_max);
	vec3 f_t_max_dist = max(f_t_min, f_t_max);
	float f_t_near = max(max(f_t_min_dist.x, f_t_min_dist.y), f_t_min_dist.z);
	float f_t_far = min(min(f_t_max_dist.x, f_t_max_dist.y), f_t_max_dist.z);

	Collision f_c;
    f_c.object_index = 3;
	f_c.t = f_t_near;
	f_c.inside = false;

	if(f_t_near >= f_t_far || f_t_far <= 0.0)
	{	
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
	
	if (f_c.n == vec3(1,0,0)) f_c.face_index = 0;
	else if (f_c.n == vec3(-1,0,0)) f_c.face_index = 1;
	else if (f_c.n == vec3(0,1,0)) f_c.face_index = 2;
	else if (f_c.n == vec3(0,-1,0)) f_c.face_index = 3;
	else if (f_c.n == vec3(0,0,1)) f_c.face_index = 4;
	else if (f_c.n == vec3(0,0,-1)) f_c.face_index = 5;
	
	float f_total_width = f_sky_box_max.x - f_sky_box_min.x;
	float f_total_height = f_sky_box_max.y - f_sky_box_min.y;
	float f_total_depth = f_sky_box_max.z - f_sky_box_min.z;
	float f_max_dim = max(f_total_width, max(f_total_height, f_total_depth));
	
	float f_ray_strike_x = ((f_c.p).x + f_total_width/2.0) / f_max_dim;
	float f_ray_strike_y = ((f_c.p).y + f_total_height/2.0) / f_max_dim;
	float f_ray_strike_z = ((f_c.p).z + f_total_depth/2.0) / f_max_dim;
	
	if (f_c.face_index == 0) {
		f_c.tc = vec2(f_ray_strike_z, f_ray_strike_y);
	} else if (f_c.face_index == 1) {
		f_c.tc = vec2(1.0 - f_ray_strike_z, f_ray_strike_y);
	} else if (f_c.face_index == 2) {
		f_c.tc = vec2(f_ray_strike_x, f_ray_strike_z);
	} else if (f_c.face_index == 3) {
		f_c.tc = vec2(f_ray_strike_x, 1.0 - f_ray_strike_z);
	} else if (f_c.face_index == 4) {
		f_c.tc = vec2(1.0 - f_ray_strike_x, f_ray_strike_y);
	} else if (f_c.face_index == 5) {
		f_c.tc = vec2(f_ray_strike_x, f_ray_strike_y);
    }
		
	return f_c;
}

Collision f_intersect_plane_object(Ray f_ray) {
    mat4 m = f_translate(f_plane_pos);
    mat4 r = f_rot_y(f_plane_y_rot);
    r *= f_rot_x(f_plane_x_rot);
    r *= f_rot_z(f_plane_z_rot);
    m *= r;
    mat4 mi = inverse(m);
    mat4 ri = inverse(r);

    vec3 f_ray_start = (mi * vec4(f_ray.start, 1.0)).xyz;
    vec3 f_ray_dir = (ri * vec4(f_ray.dir, 1.0)).xyz;

    Collision f_c;
    f_c.object_index = 4;
    f_c.inside = false;

    f_c.t = dot((vec3(0.0, 0.0, 0.0) - f_ray_start), vec3(0.0, 1.0, 0.0) / dot(f_ray_dir, vec3(0.0, 1.0, 0.0)));
    f_c.p = f_ray.start + f_c.t * f_ray.dir;
    vec3 f_intersect_point = f_ray_start + f_c.t * f_ray_dir;

    if ((abs(f_intersect_point.x) > f_plane_width/2.0) || (abs(f_intersect_point.z) > (f_plane_depth / 2.0))) {
        f_c.t = -1.0;
        return f_c;
    }

    f_c.n = vec3(0.0, 1.0, 0.0);
    if (f_ray_dir.y > 0.0) {
        f_c.n *= -1.0;
    }
    f_c.n = transpose(inverse(mat3(r))) * f_c.n;

    float f_max_dims = max(f_plane_width, f_plane_depth);
    f_c.tc = (f_intersect_point.xz + f_plane_width / 2.0) / f_max_dims;

    return f_c;
}

Collision f_get_closest_collision(Ray f_ray) {
    Collision f_c_col, f_sphere_c, f_box_c, f_sky_box_c, f_plane_c;
    f_c_col.object_index = -1;

    f_sphere_c = f_intersect_sphere_object(f_ray);
    f_box_c = f_intersect_box_object(f_ray);
    f_sky_box_c = f_intersect_sky_box_object(f_ray);
    f_plane_c = f_intersect_plane_object(f_ray);

    if ((f_sphere_c.t > 0) && ((f_sphere_c.t < f_box_c.t) || (f_box_c.t < 0))) {
        f_c_col = f_sphere_c;
    }

    if ((f_box_c.t > 0) && ((f_box_c.t < f_sphere_c.t) || (f_sphere_c.t < 0))) {
        f_c_col = f_box_c;
    }

    if ((f_sky_box_c.t > 0) && ((f_sky_box_c.t < f_sphere_c.t) || (f_sphere_c.t < 0)) && ((f_sky_box_c.t < f_box_c.t) || (f_box_c.t < 0))) {
        f_c_col = f_sky_box_c;
    }

    if ((f_plane_c.t > 0) && ((f_plane_c.t < f_sphere_c.t) || (f_sphere_c.t < 0)) && ((f_plane_c.t < f_box_c.t) || (f_box_c.t < 0))) {
        f_c_col = f_plane_c;
    }

    return f_c_col;
}

vec3 f_lighting(Ray f_ray, Collision f_c, vec4 f_object_c)
{
    Light f_light = f_lights[f_light_index];
    Material f_mat = f_materials[f_mat_index];

    vec4 f_ambient = f_global_ambient + f_light.ambient * f_mat.ambient;

    vec4 f_diffuse = vec4(0.0);
    vec4 f_specular = vec4(0.0);

    vec3 f_light_dir_v = f_light.location.xyz - f_c.p;

    Ray f_light_ray;
    f_light_ray.start = f_c.p + f_c.n * 0.01;
    f_light_ray.dir = normalize(f_light_dir_v);
    bool f_in_shadow = false;

    Collision f_c_shadow = f_get_closest_collision(f_light_ray);
    if (f_c_shadow.object_index != -1 && f_c_shadow.t < length(f_light_dir_v)) {
        f_in_shadow = true;
    }

    if (f_in_shadow == false) {
        vec3 f_light_dir = f_light_ray.dir;
        vec3 f_light_ref = normalize(reflect(f_light_dir, f_c.n));
        float f_cos_theta = dot(f_light_dir, f_c.n);
        float f_cos_phi = dot(normalize(f_ray.dir), f_light_ref);

        f_diffuse = f_light.diffuse * f_mat.diffuse * max(f_cos_theta, 0.0);
        f_specular = f_light.specular * f_mat.specular * pow(max(f_cos_phi, 0.0), f_mat.shininess);
    }

    vec4 f_l_c = f_ambient + f_diffuse;
    f_l_c = (f_object_c * f_l_c + f_specular);
    return f_l_c.xyz;
}

vec4 f_checkerboard(vec2 f_tc) {
    float f_tile_scale = 24.0;
    float f_tile = mod(floor(f_tc.x * f_tile_scale) + floor(f_tc.y * f_tile_scale), 2.0);
    return vec4((f_tile * vec3(1.0, 1.0, 1.0)).xyz, 1.0);
}

vec3 f_ray_trace(Ray f_ray) {
    Collision f_c = f_get_closest_collision(f_ray);
    if (f_c.object_index == -1) return vec3(0.0);
    if (f_c.object_index == 1) return f_lighting(f_ray, f_c, (texture(f_sphere_tex, f_c.tc)));
    if (f_c.object_index == 2) return f_lighting(f_ray, f_c, (texture(f_box_tex, f_c.tc)));
    if (f_c.object_index == 3) {
        if (f_c.face_index == 0) return texture(f_xn_tex, f_c.tc).xyz;
        if (f_c.face_index == 1) return texture(f_xp_tex, f_c.tc).xyz;
        if (f_c.face_index == 2) return texture(f_yn_tex, f_c.tc).xyz;
        if (f_c.face_index == 3) return texture(f_yp_tex, f_c.tc).xyz;
        if (f_c.face_index == 4) return texture(f_zn_tex, f_c.tc).xyz;
        if (f_c.face_index == 5) return texture(f_zp_tex, f_c.tc).xyz;
    }
    if (f_c.object_index == 4) return f_lighting(f_ray, f_c, f_checkerboard(f_c.tc)).xyz;
    return vec3(1.0, 0.0, 1.0);
}

void main()
{
    SceneData f_sd = f_scene_data[f_scene_index];
    int f_width = int(gl_NumWorkGroups.x);
    int f_height = int(gl_NumWorkGroups.y);
    ivec2 f_texel = ivec2(gl_GlobalInvocationID.xy);
    float f_x_texel = 2.0 * f_texel.x / f_width - 1.0;
    float f_y_texel = 2.0 * f_texel.y / f_height - 1.0;
    Ray f_world_ray;
    
    f_world_ray.start = f_sd.camera_position.xyz; //vec3(0.0, 0.0, f_camera_pos_z);
    vec4 f_world_ray_end = vec4(f_x_texel, f_y_texel, f_sd.camera_position.z - 1.0, 1.0);
    f_world_ray.dir = normalize(f_world_ray_end.xyz - f_world_ray.start);
    mat4 r = f_rot_y(f_sd.camera_direction.y);
    r *= f_rot_x(f_sd.camera_direction.x);
    r *= f_rot_z(f_sd.camera_direction.z);
    f_world_ray.dir = (r * vec4(f_world_ray.dir.xyz, 1.0)).xyz;
    vec4 f_output_color = vec4(f_ray_trace(f_world_ray), 1.0);
    imageStore(f_texture, f_texel, f_output_color);
}