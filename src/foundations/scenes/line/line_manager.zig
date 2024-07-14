circle: ?object.object = null,
strip: ?object.object = null,
quad: ?object.object = null,
points: [point_limit]*point = undefined,
num_points: usize = 0,
num_tangents: usize = 0,
highlighted_point: ?usize = null,
dragging_point: ?usize = null,
selected_point: ?usize = null,

const point_limit: usize = 100;
const strip_scale: f32 = 0.005;

const Manager = @This();

const vertex_shader: []const u8 = @embedFile("line_vertex.glsl");
const frag_shader: []const u8 = @embedFile("line_frag.glsl");

pub inline fn coordinate(c: f32) f32 {
    return c;
}

pub fn init(allocator: std.mem.Allocator) *Manager {
    const m = allocator.create(Manager) catch @panic("OOM");
    m.* = .{};
    return m;
}

pub fn deinit(self: *Manager, allocator: std.mem.Allocator) void {
    self.deleteCircle();
    if (self.num_points > 0) self.points[0].deinit(allocator);
    allocator.destroy(self);
}

pub fn addAt(self: *Manager, allocator: std.mem.Allocator, x: f32, z: f32, tangent: bool) void {
    if (self.dragging_point != null) return;
    if (self.num_points == self.points.len) return;
    var tangent_target: ?usize = null;
    if (tangent) blk: {
        tangent_target = self.selected_point;
        if (tangent_target == null) break :blk;
        for (0..self.num_points) |i| {
            const p = self.points[i];
            if (p.tangent == tangent_target) {
                // Already has a tangent.
                tangent_target = null;
                return;
            }
        }
    }
    const np = point.init(allocator, x, z, self.num_points, tangent_target);
    if (self.num_points == 0) {
        self.points[0] = np;
        self.num_points += 1;
        if (tangent_target != null) {
            self.num_tangents += 1;
        }
        self.initCircle();
    } else {
        var root_point = self.points[0];
        _ = root_point.addPointAtTree(x, z, np);
        self.points[self.num_points] = np;
        self.num_points += 1;
        if (tangent_target != null) {
            self.num_tangents += 1;
        }
        self.deleteCircle();
        self.initCircle();
        self.dragging_point = np.index;
    }
    self.renderStrips();
    self.renderQuads();
}

pub fn startDragging(self: *Manager, pi: usize) void {
    if (self.num_points == 0) return;
    if (self.dragging_point) |dp| {
        if (self.selected_point) |sp| {
            if (sp != dp) {
                self.unselectPoint(sp);
            }
        }
        self.selectPoint(dp);
        return;
    }
    if (self.selected_point) |sp| {
        if (sp != pi) {
            self.unselectPoint(sp);
        }
    }
    self.dragging_point = pi;
}

pub fn selectPoint(self: *Manager, pi: usize) void {
    var selected_p = self.points[pi];
    if (selected_p.tangent != null) return;
    selected_p.select();
    self.updatePointData(pi);
    self.selected_point = pi;
}

pub fn unselectPoint(self: *Manager, pi: usize) void {
    var selected_p = self.points[pi];
    selected_p.unselect();
    self.updatePointData(pi);
}

pub fn drag(self: *Manager, x: f32, z: f32) bool {
    if (self.num_points == 0) return false;
    const pi = self.dragging_point orelse return false;
    var moved_p = self.points[pi];
    moved_p.update(x, z);
    self.updatePointData(pi);
    self.renderStrips();
    return true;
}

pub fn release(self: *Manager) void {
    if (self.num_points == 0) return;
    if (self.dragging_point) |_| {
        if (self.num_points > 0) {
            var root_point = self.points[0];
            root_point.clearTree();
            for (1..self.num_points) |i| {
                const p = self.points[i];
                _ = root_point.addPointAtTree(p.x, p.z, p) orelse return;
            }
        }
    }
    self.dragging_point = null;
}

pub fn highlight(self: *Manager, index: usize) void {
    if (self.num_points == 0) return;
    if (self.highlighted_point != null) return;
    if (self.dragging_point != null) return;
    if (self.num_points == 0) return;
    if (self.highlighted_point) |hp| {
        self.points[hp].resetColor();
        self.updatePointData(hp);
    }
    self.points[index].i_data.color = point.highlighted_color;
    self.highlighted_point = index;
    self.updatePointData(index);
}

pub fn updatePointData(self: *Manager, index: usize) void {
    if (self.circle) |o| {
        switch (o) {
            .circle => |cr| cr.updateInstanceAt(index, self.points[index].i_data),
            else => {},
        }
    }
}

pub fn clearHighlight(self: *Manager) void {
    if (self.num_points == 0) return;
    const hp = self.highlighted_point orelse return;
    self.highlighted_point = null;
    self.points[hp].resetColor();
    self.updatePointData(hp);
}

pub fn draw(self: *Manager) void {
    if (self.circle) |cr| {
        const objects: [1]object.object = .{cr};
        rhi.drawObjects(objects[0..]);
    }
    if (self.strip) |s| {
        const objects: [1]object.object = .{s};
        rhi.drawObjects(objects[0..]);
    }
    if (self.quad) |q| {
        const objects: [1]object.object = .{q};
        rhi.drawObjects(objects[0..]);
    }
}

pub fn rootPoint(self: *Manager) ?*point {
    if (self.num_points > 0) {
        return self.points[0];
    }
    return null;
}

pub fn deleteCircle(self: *Manager) void {
    if (self.circle) |cr| {
        var objects: [1]object.object = .{cr};
        rhi.deleteObjects(objects[0..]);
        self.circle = null;
    }
}

pub fn deleteStrip(self: *Manager) void {
    if (self.strip) |s| {
        var objects: [1]object.object = .{s};
        rhi.deleteObjects(objects[0..]);
        self.strip = null;
    }
}

pub fn initCircle(self: *Manager) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    var i_datas: [point_limit]rhi.instanceData = undefined;
    for (0..self.num_points) |i| {
        i_datas[i] = self.points[i].i_data;
    }
    const circle: object.object = .{
        .circle = object.circle.init(
            program,
            i_datas[0..self.num_points],
        ),
    };
    self.circle = circle;
}

pub fn renderStrips(self: *Manager) void {
    const num_points = self.num_points - self.num_tangents;
    if (num_points < 2) return;
    self.deleteStrip();
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    var i_datas: [100_000]rhi.instanceData = undefined;
    var positions: [point_limit]math.vector.vec4 = undefined;
    var times: [point_limit]f32 = undefined;
    var points_added: usize = 0;
    for (0..self.num_points) |i| {
        const p = self.points[i];
        if (p.tangent != null) continue;
        positions[points_added] = p.toVector();
        times[points_added] = @floatFromInt(points_added);
        points_added += 1;
    }
    for (0..points_added * 1_000) |i| {
        const t: f32 = @floatFromInt(i);
        const sp = math.interpolation.linear(t / 1_000.0, positions[0..points_added], times[0..points_added]);
        var m = math.matrix.leftHandedXUpToNDC();
        m = math.matrix.transformMatrix(m, math.matrix.translate(sp[0], sp[1], sp[2]));
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
            i_datas[0 .. points_added * 1_000],
        ),
    };
    self.strip = strip;
}

pub fn renderQuads(self: *Manager) void {
    if (self.num_tangents < 1) return;
    self.deleteStrip();
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    var i_datas: [100]rhi.instanceData = undefined;
    for (0..self.num_points) |i| {
        const p = self.points[i];
        const tangent = p.tangent orelse continue;
        const v = math.vector.sub(p.toVector(), self.points[tangent].toVector());
        const distance = math.vector.magnitude(v);
        var m = math.matrix.leftHandedXUpToNDC();
        m = math.matrix.transformMatrix(m, math.matrix.translate(p.x, 0, p.z));
        m = math.matrix.transformMatrix(m, math.matrix.scale(0.001, 1, distance));
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
        .quad = object.quad.initInstanced(
            program,
            i_datas[0..self.num_tangents],
        ),
    };
    self.strip = strip;
}

const std = @import("std");
const math = @import("../../math/math.zig");
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
const point = @import("line_point.zig");
