program: u32,
objects: [1]object.object = undefined,
ui_state: ca_ui,
transform: math.matrix,

const LinearColorSpace = @This();

const vertex_shader: []const u8 = @embedFile("ca_vertex.glsl");
const frag_shader: []const u8 = @embedFile("ca_frag.glsl");

pub fn init(allocator: std.mem.Allocator) *LinearColorSpace {
    const p = allocator.create(LinearColorSpace) catch @panic("OOM");

    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    const cube: object.object = .{
        .cube = object.cube.init(
            program,
            object.cube.default_positions,
            .{ 1, 0, 1, 1 },
        ),
    };
    p.* = .{
        .program = program,
        .ui_state = ca_ui.init(),
        .transform = math.matrix.identity(),
    };
    p.objects[0] = cube;
    return p;
}

pub fn deinit(self: *LinearColorSpace, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *LinearColorSpace, _: f64) void {
    rhi.drawObjects(self.objects[0..]);
    rhi.setUniformMatrix(self.program, "f_transform", self.transform);
    self.ui_state.draw();
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
const ca_ui = @import("cubes_animated_ui.zig");
