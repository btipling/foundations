program: u32 = 0,
objects: [1]object.object = undefined,
cfg: *config,

const Circle = @This();

const vertex_shader: []const u8 = @embedFile("circle_vertex.glsl");
const frag_shader: []const u8 = @embedFile("circle_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .shape,
        .name = "Circle",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *Circle {
    const p = allocator.create(Circle) catch @panic("OOM");
    p.* = .{
        .cfg = cfg,
    };

    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    var m = math.matrix.orthographicProjection(0, 9, 0, 6, cfg.near, cfg.far);
    m = math.matrix.transformMatrix(m, math.matrix.leftHandedXUpToNDC());
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(0.5));
    var i_data: [1]rhi.instanceData = .{
        .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 0, 0, 1, 1 },
        },
    };
    const circle: object.object = .{
        .circle = object.circle.init(
            program,
            i_data[0..],
        ),
    };
    p.program = program;
    p.objects[0] = circle;

    return p;
}

pub fn deinit(self: *Circle, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *Circle, _: f64) void {
    rhi.drawObjects(self.objects[0..]);
    rhi.setUniformMatrix(self.program, "f_transform", math.matrix.leftHandedXUpToNDC());
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
const math = @import("../../math/math.zig");
const ui = @import("../../ui/ui.zig");
const config = @import("../../config/config.zig");
