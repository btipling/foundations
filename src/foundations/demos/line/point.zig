x: f32,
z: f32,
circle: object.object,
x_big_node: ?*Point = null,
x_small_node: ?*Point = null,
z_big_node: ?*Point = null,
z_small_node: ?*Point = null,

const Point = @This();

const vertex_shader: []const u8 = @embedFile("line_vertex.glsl");
const frag_shader: []const u8 = @embedFile("line_frag.glsl");

pub inline fn coordinate(c: f32) f32 {
    const n: f32 = @floor(c * 10) / 10;
    std.debug.print("c: {d} n: {d}\n", .{ c, n });
    return n;
}

pub fn init(allocator: std.mem.Allocator, px: f32, pz: f32, x: f32, z: f32) *Point {
    const p = allocator.create(Point) catch @panic("OOM");

    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    const circle: object.object = .{
        .circle = object.circle.init(
            program,
            .{ 1, 1, 1, 1 },
        ),
    };
    var m = math.matrix.leftHandedXUpToNDC();
    m = math.matrix.transformMatrix(m, math.matrix.translate(x, 0, z));
    m = math.matrix.transformMatrix(m, math.matrix.scale(0.05, 0.05, 0.05));
    rhi.setUniformMatrix(program, "f_transform", m);
    p.* = .{
        .x = px,
        .z = pz,
        .circle = circle,
    };
    std.debug.print("\nadded initial point ({d}, 0, {d})\n\n", .{ px, pz });
    return p;
}

pub fn deinit(self: *Point, allocator: std.mem.Allocator) void {
    if (self.x_small_node) |n| n.deinit(allocator);
    if (self.x_big_node) |n| n.deinit(allocator);
    if (self.z_small_node) |n| n.deinit(allocator);
    if (self.z_big_node) |n| n.deinit(allocator);
    allocator.destroy(self);
}

pub fn addAt(self: *Point, allocator: std.mem.Allocator, px: f32, pz: f32, x: f32, z: f32) ?*Point {
    if (self.x == px and self.z == pz) {
        std.debug.print("\n ({d}, {d}) already a point\n\n", .{ px, pz });
        return null;
    }
    if (self.x < px) {
        if (self.x_small_node) |n| {
            return n.addAt(allocator, px, pz, x, z);
        }
        self.x_small_node = init(allocator, px, pz, x, z);
        return self.x_small_node;
    }
    if (self.x > px) {
        if (self.x_big_node) |n| {
            return n.addAt(allocator, px, pz, x, z);
        }
        self.x_big_node = init(allocator, px, pz, x, z);
        return self.x_big_node;
    }
    if (self.z < pz) {
        if (self.z_small_node) |n| {
            return n.addAt(allocator, px, pz, x, z);
        }
        self.z_small_node = init(allocator, px, pz, x, z);
        return self.z_small_node;
    }
    if (self.z_big_node) |n| {
        return n.addAt(allocator, px, pz, x, z);
    }
    self.z_big_node = init(allocator, px, pz, x, z);
    return self.z_big_node;
}

pub fn getAt(self: *Point, px: f32, pz: f32) ?*Point {
    if (self.x == px and self.z == pz) return self;
    if (self.x < px) if (self.x_small_node) |n| if (n.getAt(px, pz)) |nn| return nn;
    if (self.x > px) if (self.x_big_node) |n| if (n.getAt(px, pz)) |nn| return nn;
    if (self.z < pz) if (self.z_small_node) |n| if (n.getAt(px, pz)) |nn| return nn;
    if (self.z > pz) if (self.z_big_node) |n| if (n.getAt(px, pz)) |nn| return nn;
    return null;
}

const std = @import("std");
const math = @import("../../math/math.zig");
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
