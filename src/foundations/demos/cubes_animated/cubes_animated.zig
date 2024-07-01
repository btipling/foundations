program: u32,
objects: [1]object.object = undefined,
ui_state: ca_ui,

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
    };
    p.objects[0] = cube;
    return p;
}

pub fn deinit(self: *LinearColorSpace, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *LinearColorSpace, _: f64) void {
    var m = math.matrix.identity();
    if (self.ui_state.use_lh_x_up == 1) {
        m = math.matrix.leftHandedXUpToNDC();
    }
    m = math.matrix.transformMatrix(m, math.matrix.translate(
        self.ui_state.x_translate,
        self.ui_state.y_translate,
        self.ui_state.z_translate,
    ));
    m = math.matrix.transformMatrix(m, math.matrix.scale(
        self.ui_state.scale,
        self.ui_state.scale,
        self.ui_state.scale,
    ));
    m = math.matrix.transformMatrix(m, math.matrix.rotationX(self.ui_state.x_rot));
    m = math.matrix.transformMatrix(m, math.matrix.rotationY(self.ui_state.y_rot));
    m = math.matrix.transformMatrix(m, math.matrix.rotationZ(self.ui_state.z_rot));
    rhi.drawObjects(self.objects[0..]);
    rhi.setUniformMatrix(self.program, "f_transform", m);
    const pinhole_distance: f32 = 0;
    rhi.setUniform1f(self.program, "f_pinhole", pinhole_distance);
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
