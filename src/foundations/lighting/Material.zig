ambient: [4]f32,
diffuse: [4]f32,
specular: [4]f32,
shininess: f32,
padding_1: f32 = 0,
padding_2: f32 = 0,
padding_3: f32 = 0,

const Material = @This();

pub const SSBO = rhi.storage_buffer.Buffer([]const Material, rhi.storage_buffer.bbp_materials, c.GL_STATIC_DRAW);

const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
