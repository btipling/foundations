x: f32,
z: f32,
px: f32,
pz: f32,
index: usize,
circle: ?object.object = null,
x_big_node: ?*Point = null,
x_small_node: ?*Point = null,
z_big_node: ?*Point = null,
z_small_node: ?*Point = null,
points: [100]*Point = undefined,
i_data: rhi.instanceData = undefined,
num_points: usize = 0,
highlighted_point: ?usize = null,

const Point = @This();

const normal_color: [4]f32 = .{ 1, 1, 1, 1 };
const highlighted_color: [4]f32 = .{ 1, 0, 1, 1 };

const vertex_shader: []const u8 = @embedFile("line_vertex.glsl");
const frag_shader: []const u8 = @embedFile("line_frag.glsl");

pub inline fn coordinate(c: f32) f32 {
    return c;
}
pub fn initRoot(allocator: std.mem.Allocator, x: f32, z: f32) *Point {
    const p = allocator.create(Point) catch @panic("OOM");

    var m = math.matrix.leftHandedXUpToNDC();
    m = math.matrix.transformMatrix(m, math.matrix.translate(x, 0, z));
    m = math.matrix.transformMatrix(m, math.matrix.scale(0.05, 0.05, 0.05));
    const i_data: rhi.instanceData = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 0, 0, 1, 1 },
    };
    const px = coordinate(x);
    const pz = coordinate(z);
    p.* = .{
        .x = x,
        .z = z,
        .px = px,
        .pz = pz,
        .index = 0,
        .i_data = i_data,
    };
    p.points[0] = p;
    p.num_points += 1;
    p.initCircle();
    return p;
}

pub fn init(allocator: std.mem.Allocator, x: f32, z: f32, index: usize) *Point {
    const p = allocator.create(Point) catch @panic("OOM");
    var m = math.matrix.leftHandedXUpToNDC();
    m = math.matrix.transformMatrix(m, math.matrix.translate(x, 0, z));
    m = math.matrix.transformMatrix(m, math.matrix.scale(0.05, 0.05, 0.05));
    const i_data: rhi.instanceData = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 0, 0, 1, 1 },
    };
    const px = coordinate(x);
    const pz = coordinate(z);
    p.* = .{
        .x = x,
        .z = z,
        .px = px,
        .pz = pz,
        .index = index,
        .i_data = i_data,
    };
    return p;
}

pub fn deinit(self: *Point, allocator: std.mem.Allocator) void {
    self.deleteCircle();
    if (self.x_small_node) |n| n.deinit(allocator);
    if (self.x_big_node) |n| n.deinit(allocator);
    if (self.z_small_node) |n| n.deinit(allocator);
    if (self.z_big_node) |n| n.deinit(allocator);
    allocator.destroy(self);
}

pub fn addAt(self: *Point, allocator: std.mem.Allocator, x: f32, z: f32) void {
    if (self.num_points == self.points.len) return;
    if (self.addAtTree(allocator, x, z, self.num_points)) |np| {
        self.points[self.num_points] = np;
        self.num_points += 1;
        self.deleteCircle();
        self.initCircle();
    }
}

pub fn highlight(self: *Point, index: usize) void {
    if (self.highlighted_point) |hp| {
        self.points[hp].i_data.color = normal_color;
    }
    self.points[index].i_data.color = highlighted_color;
    self.highlighted_point = index;
    self.deleteCircle();
    self.initCircle();
}

pub fn clearHighlight(self: *Point) void {
    const hp = self.highlighted_point orelse return;
    self.highlighted_point = null;
    self.points[hp].i_data.color = normal_color;
    self.deleteCircle();
    self.initCircle();
}

pub fn draw(self: *Point) void {
    if (self.circle) |c| {
        const objects: [1]object.object = .{c};
        rhi.drawObjects(objects[0..]);
    }
}

pub fn deleteCircle(self: *Point) void {
    if (self.circle) |c| {
        var objects: [1]object.object = .{c};
        rhi.deleteObjects(objects[0..]);
        self.circle = null;
    }
}

pub fn initCircle(self: *Point) void {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    var i_data: [100]rhi.instanceData = undefined;
    for (0..self.num_points) |i| {
        i_data[i] = self.points[i].i_data;
    }
    const circle: object.object = .{
        .circle = object.circle.init(
            program,
            i_data[0..self.num_points],
        ),
    };
    self.circle = circle;
}

fn addAtTree(self: *Point, allocator: std.mem.Allocator, x: f32, z: f32, index: usize) ?*Point {
    if (self.x <= x) {
        if (self.x_small_node) |n| {
            return n.addAtTree(allocator, x, z, index);
        }
        self.x_small_node = init(allocator, x, z, index);
        return self.x_small_node;
    }
    if (self.x >= x) {
        if (self.x_big_node) |n| {
            return n.addAtTree(allocator, x, z, index);
        }
        self.x_big_node = init(allocator, x, z, index);
        return self.x_big_node;
    }
    if (self.z <= z) {
        if (self.z_small_node) |n| {
            return n.addAtTree(allocator, x, z, index);
        }
        self.z_small_node = init(allocator, x, z, index);
        return self.z_small_node;
    }
    if (self.z_big_node) |n| {
        return n.addAtTree(allocator, x, z, index);
    }
    self.z_big_node = init(allocator, x, z, index);
    return self.z_big_node;
}

pub fn getAt(self: *Point, px: f32, pz: f32) ?*Point {
    if (math.float.equal(self.px, px, 0.03) and math.float.equal(self.pz, pz, 0.03)) return self;
    if (self.px <= px) if (self.x_small_node) |n| if (n.getAt(px, pz)) |nn| return nn;
    if (self.px >= px) if (self.x_big_node) |n| if (n.getAt(px, pz)) |nn| return nn;
    if (self.pz <= pz) if (self.z_small_node) |n| if (n.getAt(px, pz)) |nn| return nn;
    if (self.pz >= pz) if (self.z_big_node) |n| if (n.getAt(px, pz)) |nn| return nn;
    return null;
}

const std = @import("std");
const math = @import("../../math/math.zig");
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
