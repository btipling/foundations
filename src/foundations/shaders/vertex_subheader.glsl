
layout(std140, binding = 0) uniform CameraBuffer {
    mat4 f_mvp;
    mat4 v_matrix;
    vec4 f_camera_pos;
    vec4 f_global_ambient;
};

uniform mat4 f_model_transform;

out vec2 f_tc;
out vec4 f_frag_color;
out vec3 fo_normal;
out vec3 fo_vert;
out vec3 fo_lightdir;
out vec4 fo_tangent;
