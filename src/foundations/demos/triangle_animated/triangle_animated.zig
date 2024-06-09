program: u32,
vao: u32,
buffer: u32,
count: usize,
x: f32 = 0,
inc: f32 = 0.01,

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

pub fn draw(self: *AnimatedTriangle) void {
    self.x += self.inc;
    if (self.x >= 1) {
        self.inc = -self.inc;
    }
    if (self.x < -1) {
        self.inc = -self.inc;
    }
    rhi.setUniform1f(self.program, "f_offset", self.x);
    rhi.drawArrays(self.program, self.vao, self.count);
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
