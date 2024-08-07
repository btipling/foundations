program: u32,
vao: u32,
buffer: u32,
count: usize,
cfg: *config,

const AnimatedTriangle = @This();

const vertex_shader: []const u8 = @embedFile("vertex.glsl");
const frag_shader: []const u8 = @embedFile("frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .shape,
        .name = "Triangle animated",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *AnimatedTriangle {
    const program = rhi.createProgram();
    const vao = rhi.createVAO();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    const at = allocator.create(AnimatedTriangle) catch @panic("OOM");
    at.* = .{
        .program = program,
        .vao = vao,
        .buffer = 0,
        .count = 3,
        .cfg = cfg,
    };
    return at;
}

pub fn deinit(self: *AnimatedTriangle, allocator: std.mem.Allocator) void {
    rhi.deletePrimitive(self.program, self.vao, self.buffer);
    allocator.destroy(self);
}

const animation_duration: f64 = 2; // seconds

pub fn draw(self: *AnimatedTriangle, frame_time: f64) void {
    const is_even = @mod(@floor(frame_time / animation_duration), 2) == 0;
    const pos: f32 = @floatCast((@mod(frame_time, animation_duration) / animation_duration));
    var x: f32 = pos * 2 - 1;
    if (is_even) {
        x = 1 - pos * 2;
    }
    rhi.setUniform1f(self.program, "f_offset", x);
    rhi.drawArrays(self.program, self.vao, self.count);
    rhi.setUniformMatrix(self.program, "f_transform", math.matrix.orthographicProjection(
        0,
        9,
        0,
        6,
        self.cfg.near,
        self.cfg.far,
    ));
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
const ui = @import("../../ui/ui.zig");
const config = @import("../../config/config.zig");
const math = @import("../../math/math.zig");
