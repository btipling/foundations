strip: ?object.object = null,
circle: object.object = undefined,
triangle: math.geometry.triangle = undefined,
center: math.geometry.circle = undefined,
inscribed: math.geometry.circle = undefined,
circumscribed: math.geometry.circle = undefined,
ui_state: bc_ui,
points: [num_points]rhi.instanceData = undefined,
allocator: std.mem.Allocator,

const BCTriangle = @This();

const num_triangles: usize = 1_000;
const num_points: usize = 3;
const num_points_interpolated: usize = num_points + 1;
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
    const ui_state: bc_ui = .{};
    const t = math.geometry.triangle.init(ui_state.vs[0].position, ui_state.vs[1].position, ui_state.vs[2].position);
    const center_c_center = math.geometry.xUpLeftHandedTo2D(t.centerOfGravity());
    const center_c: math.geometry.circle = .{ .center = center_c_center, .radius = point_scale };
    const inscribed = t.incribedCircle();
    const circumscribed = t.circumscribedCircle();
    bct.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .triangle = t,
        .center = center_c,
        .inscribed = inscribed,
        .circumscribed = circumscribed,
    };

    bct.renderStrip();
    bct.renderCircle();

    return bct;
}

pub fn deinit(self: *BCTriangle, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn deleteStrip(self: *BCTriangle) void {
    if (self.strip) |s| {
        var objects: [1]object.object = .{s};
        rhi.deleteObjects(objects[0..]);
    }
}

pub fn renderStrip(self: *BCTriangle) void {
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

pub fn renderCircle(self: *BCTriangle) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    for (0..num_points) |i| self.updatePointIData(i);
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
    if (self.strip) |s| {
        const objects: [1]object.object = .{s};
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
    const p: math.vector.vec3 = .{ x, 0.0, z };
    self.ui_state.barycentric_coordinates = self.triangle.barycentricCooordinate(p);
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
        self.ui_state.vs[ov.vertex].color = bc_ui.pink;
        if (ov.dragging) {
            self.ui_state.vs[ov.vertex].position = .{ x, 0, z };
            const t = math.geometry.triangle.init(
                self.ui_state.vs[0].position,
                self.ui_state.vs[1].position,
                self.ui_state.vs[2].position,
            );
            self.triangle = t;
            self.renderStrip();
        }
        self.updatePointData(ov.vertex);
    }
}

fn releaseCurrentMouseCapture(self: *BCTriangle) void {
    const data = self.ui_state.over_vertex orelse return;
    self.ui_state.vs[data.vertex].color = bc_ui.yellow;
    self.ui_state.over_vertex = null;
    self.updatePointData(data.vertex);
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

fn overVertex(self: *BCTriangle, x: f32, z: f32) ?bc_ui.mouseVertexCapture {
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
const bc_ui = @import("bc_ui.zig");
const object = @import("../../object/object.zig");
