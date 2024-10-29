data: std.ArrayListUnmanaged(u8) = .{},
width: usize = 256,
height: usize = 256,
depth: usize = 256,
dim: usize = 4,
primary_color: math.vector.vec4 = .{ 255, 255, 0, 255 },
secondary_color: math.vector.vec4 = .{ 0, 0, 255, 255 },

const StripedPattern = @This();

pub const max_tex_dims = 256;

pub fn init(allocator: std.mem.Allocator) *StripedPattern {
    var sp = allocator.create(StripedPattern) catch @panic("OOM");
    sp.* = .{};
    sp.data = std.ArrayListUnmanaged(u8).initCapacity(
        allocator,
        sp.width * sp.height * sp.depth * sp.dim,
    ) catch @panic("OOM");
    sp.data.expandToCapacity();
    return sp;
}

pub fn deinit(self: *StripedPattern, allocator: std.mem.Allocator) void {
    self.data.deinit(allocator);
    self.data = undefined;
    allocator.destroy(self);
}

pub fn fillData(self: *StripedPattern) void {
    for (0..self.height) |h| {
        for (0..self.depth) |d| {
            for (0..self.width) |w| {
                var color: math.vector.vec4 = self.secondary_color;
                const h_f: f32 = @floatFromInt(h);
                if (@mod(h_f, 10) < 5.0) {
                    color = self.primary_color;
                }
                var i = w * self.width * self.height * self.dim;
                i += h * self.height * self.dim;
                i += d * self.dim;
                self.data.items[i + 0] = @intFromFloat(color[0]);
                self.data.items[i + 1] = @intFromFloat(color[1]);
                self.data.items[i + 2] = @intFromFloat(color[2]);
                self.data.items[i + 3] = @intFromFloat(color[3]);
            }
        }
    }
}

const std = @import("std");
const math = @import("../foundations/math/math.zig");
