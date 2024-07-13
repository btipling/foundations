circle: ?object.object = null,
strip: ?object.object = null,
points: [point_limit]*point = undefined,
num_points: usize = 0,
highlighted_point: ?usize = null,
dragging_point: ?usize = null,

const point_limit: usize = 1000;

const Manager = @This();

const normal_color: [4]f32 = .{ 1, 1, 1, 1 };
const highlighted_color: [4]f32 = .{ 1, 0, 1, 1 };

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

pub fn addAt(self: *Manager, allocator: std.mem.Allocator, x: f32, z: f32) void {
    if (self.dragging_point != null) return;
    if (self.num_points == self.points.len) return;
    if (self.num_points == 0) {
        const p = point.init(allocator, x, z, self.num_points);
        self.points[0] = p;
        self.num_points += 1;
        self.initCircle();
    } else {
        var root_point = self.points[0];
        if (root_point.addAtTree(allocator, x, z, self.num_points)) |np| {
            self.points[self.num_points] = np;
            self.num_points += 1;
            self.deleteCircle();
            self.initCircle();
            self.dragging_point = np.index;
        }
    }
    if (self.num_points > 1 and self.strip == null) {
        self.initStrip();
    }
}

pub fn startDragging(self: *Manager, pi: usize) void {
    if (self.num_points == 0) return;
    if (self.dragging_point != null) return;
    self.dragging_point = pi;
}

pub fn drag(self: *Manager, x: f32, z: f32) bool {
    if (self.num_points == 0) return false;
    const pi = self.dragging_point orelse return false;
    var moved_p = self.points[pi];
    moved_p.update(x, z);
    if (self.circle) |o| {
        switch (o) {
            .circle => |c| c.updateInstanceAt(moved_p.index, moved_p.i_data),
            else => {},
        }
    }
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
        self.points[hp].i_data.color = normal_color;
    }
    self.points[index].i_data.color = highlighted_color;
    self.highlighted_point = index;

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
    self.points[hp].i_data.color = normal_color;

    if (self.circle) |o| {
        switch (o) {
            .circle => |cr| cr.updateInstanceAt(hp, self.points[hp].i_data),
            else => {},
        }
    }
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
}

pub fn rootPoint(self: *Manager) ?*point {
    if (self.num_points > 0) {
        return self.points[0];
    }
    return null;
}

pub fn deleteCircle(self: *Manager) void {
    if (self.circle) |c| {
        var objects: [1]object.object = .{c};
        rhi.deleteObjects(objects[0..]);
        self.circle = null;
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

pub fn initStrip(self: *Manager) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    const m = math.matrix.leftHandedXUpToNDC();
    const i_data: rhi.instanceData = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 0, 0, 1, 1 },
    };
    var i_datas: [1]rhi.instanceData = .{i_data};
    const strip: object.object = .{
        .strip = object.strip.init(
            program,
            i_datas[0..],
        ),
    };
    self.strip = strip;
}

const std = @import("std");
const math = @import("../../math/math.zig");
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
const point = @import("line_point.zig");
