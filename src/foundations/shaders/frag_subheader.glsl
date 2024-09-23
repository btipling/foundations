layout(std140, binding = 0) uniform CameraBuffer {
    mat4 f_mvp;
    mat4 v_matrix;
    vec4 f_camera_pos;
};

out vec4 fo_frag_color;
uniform vec4 f_global_ambient;

in vec2 f_tc;
in vec4 f_frag_color;
in vec3 fo_normals;
in vec3 fo_vert;
in vec3 fo_lightdir;
