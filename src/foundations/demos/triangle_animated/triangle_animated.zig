program: u32,
vao: u32,
buffer: u32,
count: usize,

const AnimatedTriangle = @This();

const vertex_shader: []const u8 = @embedFile("vertex.glsl");
const frag_shader: []const u8 = @embedFile("frag.glsl");

pub fn init(allocator: std.mem.Allocator) *AnimatedTriangle {
    const program = rhi.createProgram();
    const vao = rhi.createVAO();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    const at = allocator.create(AnimatedTriangle) catch @panic("OOM");
    at.* = .{
        .program = program,
        .vao = vao,
        .buffer = 0,
        .count = 3,
    };
    return at;
}

pub fn deinit(self: *AnimatedTriangle, allocator: std.mem.Allocator) void {
    rhi.delete(self.program, self.vao, self.buffer);
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
    rhi.drawArrays(self.program, self.vao, self.count, false);
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
