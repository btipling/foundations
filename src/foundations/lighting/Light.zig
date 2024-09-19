ambient: [4]f32,
diffuse: [4]f32,
specular: [4]f32,
location: [4]f32,
direction: [4]f32,
cutoff: f32 = 0,
exponent: f32 = 0,
attenuation_constant: f32 = 0,
attenuation_linear: f32 = 0,
attenuation_quadratic: f32 = 0,
light_kind: light_type,
// Alignment
padding_1: f32 = 0,
padding_2: f32 = 0,

pub const light_type = enum(u32) {
    direction,
    positional,
    spotlight,
};
