data: std.ArrayListUnmanaged(u8) = .{},
dims: usize = 256,
dim: usize = 4,

const StripedPattern = @This();

pub const max_tex_dims = 256;

pub fn init(allocator: std.mem.Allocator) *StripedPattern {
    var sp = allocator.create(StripedPattern) catch @panic("OOM");
    sp.* = .{};
    sp.data = std.ArrayListUnmanaged(u8).initCapacity(
        allocator,
        sp.dims * sp.dims * sp.dims * sp.dim,
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
    const period: f32 = 40.0;
    const offset: f32 = 2.0;
    const dims: f32 = @floatFromInt(self.dims);
    for (0..self.dims) |h| {
        const h_f: f32 = @floatFromInt(h);
        for (0..self.dims) |d| {
            for (0..self.dims) |w| {
                const w_f: f32 = @floatFromInt(w);

                const w_val: f32 = ((w_f - dims / offset) / dims) - 0.25;
                const h_val: f32 = ((h_f - dims / offset) / dims) - 0.25;
                const depth_dist: f32 = @sqrt(w_val * w_val + h_val * h_val);
                const sine_val = (dims / offset * @abs(@sin(offset * period * depth_dist * std.math.pi))) / dims * 3;
                const r_channel: f32 = @min(80.0 * sine_val, 255.0);
                const g_channel: f32 = @min(40.0 * sine_val, 255.0);
                const b_channel: f32 = 0;

                var i = w * self.dims * self.dims * self.dim;
                i += h * self.dims * self.dim;
                i += d * self.dim;
                self.data.items[i + 0] = @intFromFloat(r_channel);
                self.data.items[i + 1] = @intFromFloat(g_channel);
                self.data.items[i + 2] = @intFromFloat(b_channel);
                self.data.items[i + 3] = 0xFF;
            }
        }
    }
}

const std = @import("std");
const math = @import("../foundations/math/math.zig");
