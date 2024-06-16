program: u32,
vao: u32,
buffer: u32,
count: usize,

const RotatingPoint = @This();

const vertex_shader: []const u8 = @embedFile("point_rotating_vertex.glsl");
const frag_shader: []const u8 = @embedFile("point_rotating_frag.glsl");

pub fn init(allocator: std.mem.Allocator) *RotatingPoint {
    const program = rhi.createProgram();
    const vao = rhi.createVAO();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    const p = allocator.create(RotatingPoint) catch @panic("OOM");
    p.* = .{
        .program = program,
        .vao = vao,
        .buffer = 0,
        .count = 1,
    };
    return p;
}

pub fn deinit(self: *RotatingPoint, allocator: std.mem.Allocator) void {
    rhi.delete(self.program, self.vao, self.buffer);
    allocator.destroy(self);
}

const rotation_time: f64 = 3;

pub fn draw(self: *RotatingPoint, frame_time: f64) void {
    const rot = @mod(frame_time, rotation_time) / rotation_time;
    const r: f32 = 0.9;
    const angle_radiants: f32 = @as(f32, @floatCast(rot)) * std.math.pi * 2;
    const xy = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec2, .{ r, angle_radiants });
    rhi.setUniformVec2(self.program, "f_rotating_point", xy);
    rhi.drawPoints(self.program, self.vao, self.count);
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
