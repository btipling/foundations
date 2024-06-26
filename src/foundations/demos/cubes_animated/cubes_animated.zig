objects: [1]object.object = undefined,

const LinearColorSpace = @This();

const vertex_shader: []const u8 = @embedFile("ca_vertex.glsl");
const frag_shader: []const u8 = @embedFile("ca_frag.glsl");

pub fn init(allocator: std.mem.Allocator) *LinearColorSpace {
    const p = allocator.create(LinearColorSpace) catch @panic("OOM");

    const cube: object.object = .{
        .cube = object.cube.init(
            vertex_shader,
            frag_shader,
            object.cube.default_positions,
            .{ 1, 0, 1, 1 },
        ),
    };
    p.objects[0] = cube;

    return p;
}

pub fn deinit(self: *LinearColorSpace, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *LinearColorSpace, _: f64) void {
    rhi.drawObjects(self.objects[0..]);
}

fn clearVectors(self: *LinearColorSpace) void {
    rhi.deleteObjects(self.objects[0..self.num_objects]);
    self.num_vectors = 0;
    self.num_objects = 0;
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
const math = @import("../../math/math.zig");
