x: f32,
z: f32,
px: f32,
pz: f32,
index: usize,
x_big_node: ?*Point = null,
x_small_node: ?*Point = null,
z_big_node: ?*Point = null,
z_small_node: ?*Point = null,
i_data: rhi.instanceData = undefined,

const point_limit: usize = 1000;

const Point = @This();

const normal_color: [4]f32 = .{ 1, 1, 1, 1 };
const highlighted_color: [4]f32 = .{ 1, 0, 1, 1 };

const vertex_shader: []const u8 = @embedFile("line_vertex.glsl");
const frag_shader: []const u8 = @embedFile("line_frag.glsl");

pub inline fn coordinate(c: f32) f32 {
    return c;
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
    if (self.x_small_node) |n| n.deinit(allocator);
    if (self.x_big_node) |n| n.deinit(allocator);
    if (self.z_small_node) |n| n.deinit(allocator);
    if (self.z_big_node) |n| n.deinit(allocator);
    allocator.destroy(self);
}

pub fn update(self: *Point, x: f32, z: f32) void {
    var m = math.matrix.leftHandedXUpToNDC();
    m = math.matrix.transformMatrix(m, math.matrix.translate(x, 0, z));
    m = math.matrix.transformMatrix(m, math.matrix.scale(0.05, 0.05, 0.05));
    const i_data: rhi.instanceData = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 1, 0, 1, 1 },
    };
    const px = coordinate(x);
    const pz = coordinate(z);
    self.x = x;
    self.z = z;
    self.px = px;
    self.pz = pz;
    self.i_data = i_data;
}

pub fn clearTree(self: *Point) void {
    if (self.x_small_node) |n| n.clearTree();
    self.x_small_node = null;
    if (self.x_big_node) |n| n.clearTree();
    self.x_big_node = null;
    if (self.z_small_node) |n| n.clearTree();
    self.z_small_node = null;
    if (self.z_big_node) |n| n.clearTree();
    self.z_big_node = null;
}

pub fn addAtTree(self: *Point, allocator: std.mem.Allocator, x: f32, z: f32, index: usize) ?*Point {
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

pub fn addPointAtTree(self: *Point, x: f32, z: f32, p: *Point) ?*Point {
    if (self.x <= x) {
        if (self.x_small_node) |n| {
            return n.addPointAtTree(x, z, p);
        }
        self.x_small_node = p;
        return self.x_small_node;
    }
    if (self.x >= x) {
        if (self.x_big_node) |n| {
            return n.addPointAtTree(x, z, p);
        }
        self.x_big_node = p;
        return self.x_big_node;
    }
    if (self.z <= z) {
        if (self.z_small_node) |n| {
            return n.addPointAtTree(x, z, p);
        }
        self.z_small_node = p;
        return self.z_small_node;
    }
    if (self.z_big_node) |n| {
        return n.addPointAtTree(x, z, p);
    }
    self.z_big_node = p;
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
