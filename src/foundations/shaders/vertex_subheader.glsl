uniform mat4 v_matrix;
uniform mat4 p_matrix;

mat4 f_mvp = p_matrix * v_matrix;

out vec2 f_tc;
out vec4 f_frag_color;
out vec3 fo_normals;
out vec3 fo_vert;
out vec3 fo_lightdir;
