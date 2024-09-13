strip: object.object = undefined,
ui_state: UnitCircleUI,
allocator: std.mem.Allocator,
circle: math.geometry.Circle,
cfg: *config,

const UnitCircle = @This();

const num_triangles: usize = 10_000;
const num_triangles_f: f32 = @floatFromInt(num_triangles);
const strip_scale: f32 = 0.005;

const vertex_shader: []const u8 = @embedFile("unit_circle_vertex.glsl");
const frag_shader: []const u8 = @embedFile("unit_circle_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Unit circle",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *UnitCircle {
    const unit_circle = allocator.create(UnitCircle) catch @panic("OOM");
    unit_circle.* = .{
        .ui_state = .{},
        .allocator = allocator,
        .circle = .{ .center = .{ 0, 0 }, .radius = 1.0 },
        .cfg = cfg,
    };

    unit_circle.renderCircle();

    return unit_circle;
}

pub fn deinit(self: *UnitCircle, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn deleteStrip(self: *UnitCircle) void {
    var objects: [1]object.object = .{self.strip};
    rhi.deleteObjects(objects[0..]);
}

pub fn renderCircle(self: *UnitCircle) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    var i_datas: [num_triangles]rhi.instanceData = undefined;
    for (0..num_triangles) |i| {
        const t: f32 = @floatFromInt(i);
        const res = self.circle.parametricCircle(t / num_triangles_f);
        var m = math.matrix.orthographicProjection(0, 9, 0, 6, self.cfg.near, self.cfg.far);
        m = math.matrix.transformMatrix(m, math.matrix.leftHandedXUpToNDC());
        m = math.matrix.transformMatrix(m, math.matrix.translate(res[1], 0.0, res[0]));
        m = math.matrix.transformMatrix(m, math.matrix.uniformScale(strip_scale));
        const i_data: rhi.instanceData = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 0.5, 0.5, 0.5, 1 },
        };
        i_datas[i] = i_data;
    }
    const strip: object.object = .{
        .strip = object.Strip.init(
            program,
            i_datas[0..],
        ),
    };
    self.strip = strip;
}

pub fn draw(self: *UnitCircle, _: f64) void {
    self.handleInput();
    const objects: [1]object.object = .{self.strip};
    rhi.drawObjects(objects[0..]);
    self.ui_state.draw();
}

fn handleInput(self: *UnitCircle) void {
    const input = ui.input.getReadOnly() orelse return;
    const x = input.coord_x orelse return;
    const z = input.coord_z orelse return;
    self.ui_state.x = x;
    self.ui_state.z = z;
    self.ui_state.over_circle = self.circle.implicitCircle(.{ z * 4.5, x * 3 }, 0.01);
    self.ui_state.within_circle = self.circle.withinCircle(.{ z * 4.5, x * 3 });
}

const std = @import("std");
const ui = @import("../../../ui/ui.zig");
const rhi = @import("../../../rhi/rhi.zig");
const math = @import("../../../math/math.zig");
const UnitCircleUI = @import("UnitCircleUI.zig");
const object = @import("../../../object/object.zig");
const config = @import("../../../config/config.zig");
