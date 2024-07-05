program: u32,
objects: [1]object.object = undefined,

const Sphere = @This();

const vertex_shader: []const u8 = @embedFile("sphere_vertex.glsl");
const frag_shader: []const u8 = @embedFile("sphere_frag.glsl");

pub fn init(allocator: std.mem.Allocator) *Sphere {
    const p = allocator.create(Sphere) catch @panic("OOM");

    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    const sphere: object.object = .{
        .sphere = object.sphere.init(
            program,
            .{ 1, 1, 1, 1 },
        ),
    };
    p.program = program;
    p.objects[0] = sphere;

    return p;
}

pub fn deinit(self: *Sphere, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *Sphere, _: f64) void {
    rhi.drawObjects(self.objects[0..]);
    rhi.setUniformMatrix(self.program, "f_transform", math.matrix.leftHandedXUpToNDC());
}

fn clearVectors(self: *Sphere) void {
    rhi.deleteObjects(self.objects[0..self.num_objects]);
    self.num_vectors = 0;
    self.num_objects = 0;
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
const math = @import("../../math/math.zig");
