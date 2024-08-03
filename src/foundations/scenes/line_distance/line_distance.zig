strip: ?object.object = null,
connection_strip: ?object.object = null,
circle: object.object = undefined,
ui_state: line_distance_ui,
line: math.geometry.line = undefined,
circles: [num_points]rhi.instanceData = undefined,
allocator: std.mem.Allocator,
cfg: *config,
ortho_persp: math.matrix,

const LineDistance = @This();

const num_triangles: usize = 20_000;
const num_points: usize = 4;
const num_points_interpolated: usize = 2;
const num_triangles_f: f32 = @floatFromInt(num_triangles);
const strip_scale: f32 = 0.005;
const point_scale: f32 = 0.025;

const vertex_last_index = 1;
const point_index = 2;
const origin_point_index = 3;

const vertex_shader: []const u8 = @embedFile("line_distance_vertex.glsl");
const frag_shader: []const u8 = @embedFile("line_distance_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Distance to line",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *LineDistance {
    const bct = allocator.create(LineDistance) catch @panic("OOM");
    const ui_state: line_distance_ui = .{};
    const ortho_persp = math.matrix.orthographicProjection(
        0,
        4.5,
        0,
        3,
        cfg.near,
        cfg.far,
    );
    bct.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .cfg = cfg,
        .ortho_persp = ortho_persp,
    };
    bct.updateLine();
    bct.renderStrip();
    bct.renderCircle();

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

pub fn deleteConnectionStrip(self: *LineDistance) void {
    if (self.connection_strip) |s| {
        var objects: [1]object.object = .{s};
        rhi.deleteObjects(objects[0..]);
    }
}

pub fn renderCircle(self: *LineDistance) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    for (0..num_points - 1) |i| self.updatePointIData(i);
    const circle: object.object = .{
        .circle = object.circle.init(
            program,
            self.circles[0..],
        ),
    };
    self.circle = circle;
}

pub fn renderStrip(self: *LineDistance) void {
    self.deleteStrip();
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    var i_datas: [num_points_interpolated * num_triangles]rhi.instanceData = undefined;
    var positions: [num_points_interpolated]math.vector.vec4 = undefined;
    var times: [num_points_interpolated]f32 = undefined;
    const p0 = self.line.pointOnLine(-2);
    const p1 = self.line.pointOnLine(2);
    positions[0] = .{ p0[0], p0[1], p0[2], 1.0 };
    positions[1] = .{ p1[0], p1[1], p1[2], 1.0 };
    times[0] = 0;
    times[1] = 1;
    for (0..num_points_interpolated * num_triangles) |i| {
        const t: f32 = @floatFromInt(i);
        const res = math.interpolation.linear(t / 1_000.0, positions[0..num_points_interpolated], times[0..num_points_interpolated]);
        var m = math.matrix.transformMatrix(self.ortho_persp, math.matrix.leftHandedXUpToNDC());
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
    self.renderConnectionStrip();
}

pub fn renderConnectionStrip(self: *LineDistance) void {
    const pv = self.ui_state.point_vector orelse return;
    self.deleteConnectionStrip();
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    var i_datas: [num_points_interpolated * num_triangles]rhi.instanceData = undefined;
    var positions: [num_points_interpolated]math.vector.vec4 = undefined;
    var times: [num_points_interpolated]f32 = undefined;
    const p0 = pv.position;
    const p1 = self.line.vectorToPoint(p0);
    positions[0] = .{ p0[0], p0[1], p0[2], 1.0 };
    positions[1] = .{ p1[0], p1[1], p1[2], 1.0 };
    std.debug.print("wtf bro ({any})\n", .{positions});
    times[0] = 0;
    times[1] = 1;
    for (0..num_points_interpolated * num_triangles) |i| {
        const t: f32 = @floatFromInt(i);
        const res = math.interpolation.linear(t / 1_000.0, positions[0..num_points_interpolated], times[0..num_points_interpolated]);
        var m = math.matrix.transformMatrix(self.ortho_persp, math.matrix.leftHandedXUpToNDC());
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
    self.connection_strip = strip;
}

pub fn draw(self: *LineDistance, _: f64) void {
    self.handleInput();
    if (self.strip) |s| {
        const objects: [1]object.object = .{s};
        rhi.drawObjects(objects[0..]);
    }
    if (self.connection_strip) |s| {
        const objects: [1]object.object = .{s};
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{self.circle};
        rhi.drawObjects(objects[0..]);
    }
    self.ui_state.draw();
}

fn handleInput(self: *LineDistance) void {
    const input = ui.input.getReadOnly() orelse return;
    const x = input.coord_x orelse return;
    const z = input.coord_z orelse return;
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
        }
        self.updatePointData(ov.vertex);
    } else if (action == c.GLFW_PRESS and button == c.GLFW_MOUSE_BUTTON_1) {
        self.ui_state.point_vector = .{
            .position = .{ x, 0, z },
            .color = line_distance_ui.green,
        };
        self.renderStrip();
        self.updateLine();
        self.updatePointData(point_index);
    }
}

fn updateLine(self: *LineDistance) void {
    const vs0 = self.ui_state.vs[0].position;
    const vs1 = self.ui_state.vs[1].position;
    self.line = math.geometry.line.init(vs0, vs1);
    self.ui_state.origin_point = .{
        .position = self.line.closestPointToOrigin(),
        .color = line_distance_ui.green,
    };
    if (self.ui_state.point_vector) |pv| {
        self.ui_state.distance = self.line.distanceToPoint(pv.position);
    }
    self.updatePointData(origin_point_index);
}

fn releaseCurrentMouseCapture(self: *LineDistance) void {
    const data = self.ui_state.over_vertex orelse return;
    self.ui_state.vs[data.vertex].color = line_distance_ui.yellow;
    self.ui_state.over_vertex = null;
    self.updatePointData(data.vertex);
}

fn updatePointIData(self: *LineDistance, index: usize) void {
    var m = math.matrix.transformMatrix(self.ortho_persp, math.matrix.leftHandedXUpToNDC());
    var p: math.vector.vec3 = undefined;
    var color: math.vector.vec4 = undefined;
    var scale: f32 = 0;
    switch (index) {
        point_index => {
            const pv = self.ui_state.point_vector orelse return;
            p = pv.position;
            scale = point_scale;
            color = pv.color;
        },
        origin_point_index => {
            const op = self.ui_state.origin_point;
            p = op.position;
            scale = point_scale;
            color = op.color;
        },
        else => {
            p = self.ui_state.vs[index].position;
            scale = point_scale;
            color = self.ui_state.vs[index].color;
        },
    }
    if (index <= vertex_last_index) {} else if (index == point_index) {}
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
const config = @import("../../config/config.zig");
