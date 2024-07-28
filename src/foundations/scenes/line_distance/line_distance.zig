strip: ?object.object = null,
circle: object.object = undefined,
ui_state: line_distance_ui,
circles: [num_points]rhi.instanceData = undefined,
allocator: std.mem.Allocator,

const LineDistance = @This();

const num_triangles: usize = 1_000;
const num_points: usize = 3;
const num_points_interpolated: usize = num_points - 1;
const num_triangles_f: f32 = @floatFromInt(num_triangles);
const strip_scale: f32 = 0.005;
const point_scale: f32 = 0.025;

const vertex_last_index = 2;
const center_circle_index = 3;
const inscribed_circle_index = 4;
const circumscribed_circle_index = 5;

const vertex_shader: []const u8 = @embedFile("line_distance_vertex.glsl");
const frag_shader: []const u8 = @embedFile("line_distance_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Distance to line",
    };
}

pub fn init(allocator: std.mem.Allocator) *LineDistance {
    const bct = allocator.create(LineDistance) catch @panic("OOM");
    const ui_state: line_distance_ui = .{};
    bct.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
    };
    bct.updateLine();
    bct.renderStrip();

    return bct;
}

pub fn deinit(self: *LineDistance, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn deleteStrip(self: *LineDistance) void {
    if (self.strip) |s| {
        var objects: [1]object.object = .{s};
        rhi.deleteObjects(objects[0..]);
    }
}

pub fn renderStrip(self: *LineDistance) void {
    self.deleteStrip();
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    var i_datas: [num_points_interpolated * num_triangles]rhi.instanceData = undefined;
    var positions: [num_points_interpolated]math.vector.vec4 = undefined;
    var times: [num_points_interpolated]f32 = undefined;
    for (0..num_points_interpolated) |i| {
        const v = self.ui_state.vs[@mod(i, 3)].position;
        positions[i] = .{ v[0], v[1], v[2], 1.0 };
        times[i] = @floatFromInt(i);
    }
    for (0..num_points_interpolated * num_triangles) |i| {
        const t: f32 = @floatFromInt(i);
        const res = math.interpolation.linear(t / 1_000.0, positions[0..num_points_interpolated], times[0..num_points_interpolated]);
        var m = math.matrix.leftHandedXUpToNDC();
        m = math.matrix.transformMatrix(m, math.matrix.translate(res[0], res[1], res[2]));
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

pub fn draw(self: *LineDistance, _: f64) void {
    self.handleInput();
    if (self.strip) |s| {
        const objects: [1]object.object = .{s};
        rhi.drawObjects(objects[0..]);
    }
    // {
    //     const objects: [1]object.object = .{self.circle};
    //     rhi.drawObjects(objects[0..]);
    // }
    self.ui_state.draw();
}

fn handleInput(self: *LineDistance) void {
    const input = ui.input.getReadOnly() orelse return;
    const x = input.mouse_x orelse return;
    const z = input.mouse_z orelse return;
    const action = input.mouse_action;
    const button = input.mouse_button;
    self.ui_state.x = x;
    self.ui_state.z = z;
    if (action == c.GLFW_RELEASE) {
        self.releaseCurrentMouseCapture();
        return;
    }
    blk: {
        const ovi = self.overVertex(x, z);
        const ov = self.ui_state.over_vertex orelse {
            self.ui_state.over_vertex = ovi;
            break :blk;
        };
        const novi = ovi orelse {
            if (!ov.dragging) self.releaseCurrentMouseCapture();
            break :blk;
        };
        if (ov.vertex == novi.vertex) break :blk;
        self.releaseCurrentMouseCapture();
        self.ui_state.over_vertex = novi;
    }

    if (self.ui_state.over_vertex) |*ov| {
        if (action == c.GLFW_PRESS and button == c.GLFW_MOUSE_BUTTON_1) {
            ov.dragging = true;
            self.ui_state.over_vertex = ov.*;
        }
        self.ui_state.vs[ov.vertex].color = line_distance_ui.pink;
        if (ov.dragging) {
            self.ui_state.vs[ov.vertex].position = .{ x, 0, z };
            self.renderStrip();
            self.updateLine();
            self.updateCircle();
        }
        self.updatePointData(ov.vertex);
    }
}

fn updateLine(_: *LineDistance) void {}

fn updateCircle(self: *LineDistance) void {
    self.updatePointData(center_circle_index);
    self.updatePointData(inscribed_circle_index);
    self.updatePointData(circumscribed_circle_index);
}

fn releaseCurrentMouseCapture(self: *LineDistance) void {
    const data = self.ui_state.over_vertex orelse return;
    self.ui_state.vs[data.vertex].color = line_distance_ui.yellow;
    self.ui_state.over_vertex = null;
    self.updatePointData(data.vertex);
}

fn updatePointIData(self: *LineDistance, index: usize) void {
    var m = math.matrix.leftHandedXUpToNDC();
    var p: math.vector.vec3 = undefined;
    var color: math.vector.vec4 = undefined;
    var scale: f32 = 0;
    p = self.ui_state.vs[index].position;
    scale = point_scale;
    color = self.ui_state.vs[index].color;
    m = math.matrix.transformMatrix(m, math.matrix.translate(p[0], p[1], p[2]));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(scale));
    const i_data: rhi.instanceData = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = color,
    };
    self.circles[index] = i_data;
}

fn updatePointData(self: *LineDistance, index: usize) void {
    self.updatePointIData(index);
    switch (self.circle) {
        .circle => |cr| cr.updateInstanceAt(index, self.circles[index]),
        else => {},
    }
}

fn overVertex(self: *LineDistance, x: f32, z: f32) ?line_distance_ui.mouseVertexCapture {
    const p = math.geometry.xUpLeftHandedTo2D(.{ x, 0.0, z });
    for (self.ui_state.vs, 0..) |vs, i| {
        const center = math.geometry.xUpLeftHandedTo2D(vs.position);
        const circle: math.geometry.circle = .{ .center = center, .radius = point_scale };
        if (circle.withinCircle(p)) {
            return .{
                .vertex = i,
            };
        }
    }
    return null;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const line_distance_ui = @import("line_distance_ui.zig");
const object = @import("../../object/object.zig");
