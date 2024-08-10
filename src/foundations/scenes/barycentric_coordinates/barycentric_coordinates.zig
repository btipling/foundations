strip: ?object.object = null,
circle: object.object = undefined,
triangle: math.geometry.triangle = undefined,
center: math.geometry.circle = undefined,
inscribed: math.geometry.circle = undefined,
circumscribed: math.geometry.circle = undefined,
ui_state: bc_ui,
circles: [num_circles]rhi.instanceData = undefined,
allocator: std.mem.Allocator,
cfg: *config,
ortho_persp: math.matrix,

const BCTriangle = @This();

const num_triangles: usize = 1_000;
const num_points: usize = 3;
const num_circles = num_points + 3;
const num_points_interpolated: usize = num_points + 1;
const num_triangles_f: f32 = @floatFromInt(num_triangles);
const strip_scale: f32 = 0.005;
const point_scale: f32 = 0.025;

const vertex_last_index = 2;
const center_circle_index = 3;
const inscribed_circle_index = 4;
const circumscribed_circle_index = 5;

const vertex_shader: []const u8 = @embedFile("bc_vertex.glsl");
const frag_shader: []const u8 = @embedFile("bc_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Barycentric coordinates",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config, _: *c.ecs_world_t) *BCTriangle {
    const bct = allocator.create(BCTriangle) catch @panic("OOM");
    const ui_state: bc_ui = .{};
    const ortho_persp = math.matrix.orthographicProjection(
        0,
        9,
        0,
        6,
        cfg.near,
        cfg.far,
    );
    bct.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .cfg = cfg,
        .ortho_persp = ortho_persp,
    };
    bct.updateTriangle();
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
        const res = math.interpolation.linear(
            t / 1_000.0,
            positions[0..num_points_interpolated],
            times[0..num_points_interpolated],
        );
        var m = self.ortho_persp;
        m = math.matrix.transformMatrix(m, math.matrix.leftHandedXUpToNDC());
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
    self.updatePointIData(center_circle_index);
    self.updatePointIData(inscribed_circle_index);
    self.updatePointIData(circumscribed_circle_index);
    const circle: object.object = .{
        .circle = object.circle.init(
            program,
            self.circles[0..],
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
    const x = input.coord_x orelse return;
    const z = input.coord_z orelse return;
    const action = input.mouse_action;
    const button = input.mouse_button;
    self.ui_state.x = x;
    self.ui_state.z = z;
    const p4: math.vector.vec4 = .{ x, 0, z, 1.0 };
    const np: math.vector.vec4 = .{ x * 3.0, 0, z * 4.5, 1.0 };
    const p3 = math.vector.vec4ToVec3(np);
    self.ui_state.barycentric_coordinates = self.triangle.barycentricCooordinate(p3);
    if (action == c.GLFW_RELEASE) {
        self.releaseCurrentMouseCapture();
        return;
    }
    blk: {
        const ovi = self.overVertex(p4);
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
            self.ui_state.vs[ov.vertex].position = np;
            self.renderStrip();
            self.updateTriangle();
            self.updateCircle();
        }
        self.updatePointData(ov.vertex);
    }
}

fn updateTriangle(self: *BCTriangle) void {
    const t = math.geometry.triangle.init(
        math.vector.vec4ToVec3(self.ui_state.vs[0].position),
        math.vector.vec4ToVec3(self.ui_state.vs[1].position),
        math.vector.vec4ToVec3(self.ui_state.vs[2].position),
    );
    self.triangle = t;
    const center_c_center = math.geometry.xUpLeftHandedTo2D(t.centerOfGravity());
    self.center = .{ .center = center_c_center, .radius = point_scale };
    self.inscribed = t.incribedCircle();
    self.circumscribed = t.circumscribedCircle();
    self.ui_state.area = t.area();
    self.ui_state.perimiter = t.perimiter();
}

fn updateCircle(self: *BCTriangle) void {
    self.updatePointData(center_circle_index);
    self.updatePointData(inscribed_circle_index);
    self.updatePointData(circumscribed_circle_index);
}

fn releaseCurrentMouseCapture(self: *BCTriangle) void {
    const data = self.ui_state.over_vertex orelse return;
    self.ui_state.vs[data.vertex].color = bc_ui.yellow;
    self.ui_state.over_vertex = null;
    self.updatePointData(data.vertex);
}

fn updatePointIData(self: *BCTriangle, index: usize) void {
    var p: math.vector.vec4 = undefined;
    var color: math.vector.vec4 = undefined;
    var scale: f32 = 0;
    switch (index) {
        center_circle_index => {
            p = math.geometry.TwoDToXUpLeftHandedTo(self.center.center);
            scale = self.center.radius;
            color = .{ 1.0, 0.255, 0.212, 1 };
        },
        inscribed_circle_index => {
            p = math.geometry.TwoDToXUpLeftHandedTo(self.inscribed.center);
            scale = self.inscribed.radius;
            color = .{ 0.4, 0.8, 0.8, 1 };
        },
        circumscribed_circle_index => {
            p = math.geometry.TwoDToXUpLeftHandedTo(self.circumscribed.center);
            scale = self.circumscribed.radius;
            color = .{ 0.596, 1.0, 0.596, 1 };
        },
        else => {
            p = self.ui_state.vs[index].position;
            scale = point_scale;
            color = self.ui_state.vs[index].color;
        },
    }
    var m = self.ortho_persp;
    m = math.matrix.transformMatrix(m, math.matrix.leftHandedXUpToNDC());
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

fn updatePointData(self: *BCTriangle, index: usize) void {
    self.updatePointIData(index);
    switch (self.circle) {
        .circle => |cr| cr.updateInstanceAt(index, self.circles[index]),
        else => {},
    }
}

fn overVertex(self: *BCTriangle, pos: math.vector.vec4) ?bc_ui.mouseVertexCapture {
    const m = math.matrix.transformMatrix(self.ortho_persp, math.matrix.leftHandedXUpToNDC());
    const p: math.vector.vec2 = .{ pos[2], pos[0] };
    for (self.ui_state.vs, 0..) |vs, i| {
        const v = math.matrix.transformVector(
            m,
            vs.position,
        );
        const center = .{ v[0], v[1] };
        const circle: math.geometry.circle = .{ .center = center, .radius = point_scale };
        if (circle.withinCircle(.{ p[0], p[1] })) {
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
const config = @import("../../config/config.zig");
