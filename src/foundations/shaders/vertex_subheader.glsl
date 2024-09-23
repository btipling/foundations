
layout(std140, binding = 0) uniform CameraBuffer {
    mat4 f_mvp;
    mat4 v_matrix;
    vec4 f_camera_pos;
};

uniform vec4 f_global_ambient;

out vec2 f_tc;
out vec4 f_frag_color;
out vec3 fo_normals;
out vec3 fo_vert;
out vec3 fo_lightdir;
