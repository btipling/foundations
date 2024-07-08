x: f32,
z: f32,
circle: object.object,
index: usize,
x_big_node: ?*Point = null,
x_small_node: ?*Point = null,
z_big_node: ?*Point = null,
z_small_node: ?*Point = null,

const Point = @This();

const vertex_shader: []const u8 = @embedFile("line_vertex.glsl");
const frag_shader: []const u8 = @embedFile("line_frag.glsl");

pub inline fn coordinate(c: f32) f32 {
    var n: f32 = @floor(c * 10) / 10;
    n += 0.075;
    return n;
}

pub fn init(allocator: std.mem.Allocator, px: f32, pz: f32, index: usize) *Point {
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
    m = math.matrix.transformMatrix(m, math.matrix.translate(px, 0, pz));
    m = math.matrix.transformMatrix(m, math.matrix.scale(0.05, 0.05, 0.05));
    rhi.setUniformMatrix(program, "f_transform", m);
    rhi.setUniformVec4(program, "f_highlighted_color", .{ 1, 1, 1, 1 });
    p.* = .{
        .x = px,
        .z = pz,
        .circle = circle,
        .index = index,
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

pub fn addAt(self: *Point, allocator: std.mem.Allocator, px: f32, pz: f32, index: usize) ?*Point {
    if (self.x == px and self.z == pz) {
        std.debug.print("\n ({d}, {d}) already a point\n\n", .{ px, pz });
        return null;
    }
    if (self.x < px) {
        if (self.x_small_node) |n| {
            return n.addAt(allocator, px, pz, index);
        }
        self.x_small_node = init(allocator, px, pz, index);
        return self.x_small_node;
    }
    if (self.x > px) {
        if (self.x_big_node) |n| {
            return n.addAt(allocator, px, pz, index);
        }
        self.x_big_node = init(allocator, px, pz, index);
        return self.x_big_node;
    }
    if (self.z < pz) {
        if (self.z_small_node) |n| {
            return n.addAt(allocator, px, pz, index);
        }
        self.z_small_node = init(allocator, px, pz, index);
        return self.z_small_node;
    }
    if (self.z_big_node) |n| {
        return n.addAt(allocator, px, pz, index);
    }
    self.z_big_node = init(allocator, px, pz, index);
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
