layout(std140, binding = 0) uniform CameraBuffer {
    mat4 f_mvp;
    mat4 v_matrix;
    vec4 f_camera_pos;
    vec4 f_global_ambient;
};

out vec4 fo_frag_color;

in vec2 f_tc;
in vec4 f_frag_color;
in vec3 fo_normal;
in vec3 fo_vert;
in vec3 fo_lightdir;
in vec4 fo_tangent;
