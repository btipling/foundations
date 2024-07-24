strip: object.object = undefined,
circle: object.object = undefined,
ui_state: bc_ui,
points: [3]rhi.instanceData = undefined,
allocator: std.mem.Allocator,

const BCTriangle = @This();

const num_triangles: usize = 10_000;
const num_cirles: usize = 3;
const num_triangles_f: f32 = @floatFromInt(num_triangles);
const strip_scale: f32 = 0.005;
const point_scale: f32 = 0.05;

const vertex_shader: []const u8 = @embedFile("bc_vertex.glsl");
const frag_shader: []const u8 = @embedFile("bc_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Barycentric coordinates",
    };
}

pub fn init(allocator: std.mem.Allocator) *BCTriangle {
    const bct = allocator.create(BCTriangle) catch @panic("OOM");
    bct.* = .{
        .ui_state = .{},
        .allocator = allocator,
    };

    bct.renderStrip();
    bct.renderCircle();

    return bct;
}

pub fn deinit(self: *BCTriangle, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn deleteStrip(self: *BCTriangle) void {
    var objects: [1]object.object = .{self.strip};
    rhi.deleteObjects(objects[0..]);
}

pub fn renderStrip(self: *BCTriangle) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    var i_datas: [num_triangles]rhi.instanceData = undefined;
    for (0..num_triangles) |i| {
        const t: f32 = @floatFromInt(i);
        const res = math.geometry.parametricCircle(t / num_triangles_f);
        var m = math.matrix.leftHandedXUpToNDC();
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
        .strip = object.strip.init(
            program,
            i_datas[0..],
        ),
    };
    self.strip = strip;
}

pub fn renderCircle(self: *BCTriangle) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    for (0..num_cirles) |i| self.updatePointIData(i);
    const circle: object.object = .{
        .circle = object.circle.init(
            program,
            self.points[0..],
        ),
    };
    self.circle = circle;
}

pub fn draw(self: *BCTriangle, _: f64) void {
    self.handleInput();
    {
        const objects: [1]object.object = .{self.strip};
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{self.circle};
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

fn handleInput(self: *BCTriangle) void {
    const input = ui.input.getReadOnly() orelse return;
    const x = input.mouse_x orelse return;
    const z = input.mouse_z orelse return;
    const action = input.mouse_action;
    const button = input.mouse_button;
    self.ui_state.x = x;
    self.ui_state.z = z;
    self.ui_state.over_circle = math.geometry.implicitCircle(.{ 0, 0 }, 1.0, .{ z, x }, 0.01);
    self.ui_state.within_circle = math.geometry.withinCircle(.{ 0, 0 }, 1.0, .{ z, x });

    const ovi = self.overVertex(x, z);
    if (ovi != self.ui_state.over_vertex) {
        if (self.ui_state.over_vertex) |vi| {
            self.ui_state.vs[vi].color = bc_ui.yellow;
            self.ui_state.over_vertex = null;
            self.updatePointData(vi);
        }
    }
    self.ui_state.over_vertex = ovi;
    if (self.ui_state.over_vertex) |vi| {
        self.ui_state.vs[vi].color = bc_ui.pink;
        if (action == c.GLFW_PRESS and button == c.GLFW_MOUSE_BUTTON_1) {
            self.ui_state.vs[vi].position = .{ x, 0, z };
        }
        self.updatePointData(vi);
    }
}

fn updatePointIData(self: *BCTriangle, index: usize) void {
    var m = math.matrix.leftHandedXUpToNDC();
    const v = self.ui_state.vs[index];
    const p = v.position;
    m = math.matrix.transformMatrix(m, math.matrix.translate(p[0], p[1], p[2]));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(point_scale));
    const i_data: rhi.instanceData = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = v.color,
    };
    self.points[index] = i_data;
}

fn updatePointData(self: *BCTriangle, index: usize) void {
    self.updatePointIData(index);
    switch (self.circle) {
        .circle => |cr| cr.updateInstanceAt(index, self.points[index]),
        else => {},
    }
}

fn overVertex(self: *BCTriangle, x: f32, z: f32) ?usize {
    for (self.ui_state.vs, 0..) |v, i| {
        const p = v.position;
        if (math.geometry.withinCircle(.{ z, x }, point_scale, .{ p[2], p[0] })) {
            return i;
        }
    }
    return null;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const bc_ui = @import("bc_ui.zig");
const object = @import("../../object/object.zig");
