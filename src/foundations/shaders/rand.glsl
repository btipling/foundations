uint pcg(uint v) {
	uint state = v * uint(747796405) + uint(2891336453);
	uint word = ((state >> ((state >> uint(28)) + uint(4))) ^ state) * uint(277803737);
	return (word >> uint(22)) ^ word;
}

float prng (float p) {
	return float(pcg(uint(p))) / float(uint(0xffffffff));
}

float prng (vec2 p) {
	return float(pcg(pcg(uint(p.x)) + uint(p.y))) / float(uint(0xffffffff));
}

uvec3 pcg(uvec3 v) {
	v = v * uint(1664525) + uint(1013904223);

	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;

	v ^= v >> uint(16);

	v.x += v.y * v.z;
	v.y += v.z * v.x;
	v.z += v.x * v.y;

	return v;
}

vec3 prng (vec3 p) {
	return vec3(pcg(uvec3(p))) / float(uint(0xffffffff));
}

uvec4 pcg(uvec4 v) {
	v = v * uint(1664525) + uint(1013904223);

	v.x += v.y * v.w;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v.w += v.y * v.z;

	v.x += v.y * v.w;
	v.y += v.z * v.x;
	v.z += v.x * v.y;
	v.w += v.y * v.z;

	v = v ^ (v >> uint(16));

	return v;
}

vec4 prng (vec4 p) {
	return vec4(pcg(uvec4(p))) / float(uint(0xffffffff));
}