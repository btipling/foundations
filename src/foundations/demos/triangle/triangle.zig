program: u32,
vao: u32,
buffer: u32,
count: usize,

const Triangle = @This();

const positions: [3][3]f32 = .{
    .{ -0.5, 0.5, -0.5 },
    .{ -0.5, -0.5, -0.5 },
    .{ 0.5, -0.5, -0.5 },
};

const colors: [3][4]f32 = .{
    .{ 0, 1, 0, 1 },
    .{ 0, 0, 1, 1 },
    .{ 1, 0, 0, 1 },
};

const vertex_shader: []const u8 = @embedFile("vertex.glsl");
const frag_shader: []const u8 = @embedFile("frag.glsl");

pub fn init(allocator: std.mem.Allocator) *Triangle {
    const t = allocator.create(Triangle) catch @panic("OOM");
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    var data: [3]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        data[i] = .{
            .position = positions[i],
            .color = colors[i],
        };
    }
    const vao_buf = rhi.attachBuffer(data[0..]);
    t.* = .{
        .program = program,
        .vao = vao_buf.vao,
        .buffer = vao_buf.buffer,
        .count = positions.len,
    };
    return t;
}

pub fn deinit(self: *Triangle, allocator: std.mem.Allocator) void {
    rhi.delete(self.program, self.vao, self.buffer);
    allocator.destroy(self);
}

pub fn draw(self: *Triangle, _: f64) void {
    rhi.drawArrays(self.program, self.vao, self.count, true);
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
