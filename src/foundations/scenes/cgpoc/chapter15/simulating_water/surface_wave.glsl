
layout(bindless_sampler) uniform sampler3D f_wave_samp;

vec3 f_estimate_wave_normal(float f_w_offset, float f_w_map_scale, float f_w_h_scale)
{
    float f_depth_offset = f_waterdata[1];
	float f_h1 = 1.0 - (texture(f_wave_samp, vec3(((f_tc.s)) * f_w_map_scale, f_depth_offset, ((f_tc.t) + f_w_offset) * f_w_map_scale))).r * f_w_h_scale;
	float f_h2 = 1.0 - (texture(f_wave_samp, vec3(((f_tc.s) - f_w_offset) * f_w_map_scale, f_depth_offset, ((f_tc.t) - f_w_offset) * f_w_map_scale))).r * f_w_h_scale;
	float f_h3 = 1.0 - (texture(f_wave_samp, vec3(((f_tc.s) + f_w_offset) * f_w_map_scale, f_depth_offset, ((f_tc.t) - f_w_offset) * f_w_map_scale))).r * f_w_h_scale;
	vec3 f_v1 = vec3(0.0, f_h1, -1.0);
	vec3 f_v2 = vec3(-1.0, f_h2, 1.0);
	vec3 f_v3 = vec3(1.0, f_h3, 1.0);
	vec3 f_v4 = f_v2 - f_v1;
	vec3 f_v5 = f_v3 - f_v1;
	vec3 f_wn = normalize(cross(f_v4, f_v5));
	return normalize(vec3(f_wn.y, f_wn.z, f_wn.x));
}