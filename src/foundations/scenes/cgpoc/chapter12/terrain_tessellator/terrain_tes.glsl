#version 460

//#include "src/foundations/shaders/camera.glsl"

uniform mat4 f_terrain_m;

layout (quads, equal_spacing, ccw) in;
in vec2 f_tc_tcs[];
out vec2 f_tc_tes;

void main(void)
{
    vec3 p00 = (gl_in[0].gl_Position).xyz;
    vec3 p10 = (gl_in[1].gl_Position).xyz;
    vec3 p20 = (gl_in[2].gl_Position).xyz;
    vec3 p30 = (gl_in[3].gl_Position).xyz;
    vec3 p01 = (gl_in[4].gl_Position).xyz;
    vec3 p11 = (gl_in[5].gl_Position).xyz;
    vec3 p21 = (gl_in[6].gl_Position).xyz;
    vec3 p31 = (gl_in[7].gl_Position).xyz;
    vec3 p02 = (gl_in[8].gl_Position).xyz;
    vec3 p12 = (gl_in[9].gl_Position).xyz;
    vec3 p22 = (gl_in[10].gl_Position).xyz;
    vec3 p32 = (gl_in[11].gl_Position).xyz;
    vec3 p03 = (gl_in[12].gl_Position).xyz;
    vec3 p13 = (gl_in[13].gl_Position).xyz;
    vec3 p23 = (gl_in[14].gl_Position).xyz;
    vec3 p33 = (gl_in[15].gl_Position).xyz;
    
    float u = gl_TessCoord.x;
    float v = gl_TessCoord.y;

    float bu0 = (1.0-u) * (1.0-u) * (1.0-u);
    float bu1 = 3.0 * u * (1.0-u) * (1.0-u);
    float bu2 = 3.0 * u * u * (1.0-u);
    float bu3 = u * u * u;
    
    float bv0 = (1.0-v) * (1.0-v) * (1.0-v);
    float bv1 = 3.0 * v * (1.0-v) * (1.0-v);
    float bv2 = 3.0 * v * v * (1.0-v);
    float bv3 = v * v * v;

    vec3 f_op =
        bu0 * (bv0*p00 + bv1*p01 + bv2*p02 + bv3*p03)
      + bu1 * (bv0*p10 + bv1*p11 + bv2*p12 + bv3*p13)
      + bu2 * (bv0*p20 + bv1*p21 + bv2*p22 + bv3*p23)
      + bu3 * (bv0*p30 + bv1*p31 + bv2*p32 + bv3*p33);
    
    gl_Position = f_mvp * f_terrain_m * vec4(f_op.y, f_op.z, f_op.x, 1.0);

    vec2 f_tc1 = mix(f_tc_tcs[0], f_tc_tcs[3], gl_TessCoord.x);
    vec2 f_tc2 = mix(f_tc_tcs[12], f_tc_tcs[15], gl_TessCoord.x);
    f_tc_tes = mix(f_tc2, f_tc1, gl_TessCoord.y);
}