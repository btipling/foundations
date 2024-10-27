data: std.ArrayListUnmanaged(u8) = .{},
dims: usize = 256,
dim: usize = 4,
turb: f32 = 4,
max_zoom: f32 = 32,
freq: f32 = 3,
noise_3d: *noise.Noise3D = undefined,

const StripedPattern = @This();

pub const max_tex_dims = 256;

pub fn init(allocator: std.mem.Allocator) *StripedPattern {
    var sp = allocator.create(StripedPattern) catch @panic("OOM");
    sp.* = .{
        .noise_3d = noise.Noise3D.init(allocator),
    };
    sp.data = std.ArrayListUnmanaged(u8).initCapacity(
        allocator,
        sp.dims * sp.dims * sp.dims * sp.dim,
    ) catch @panic("OOM");
    sp.data.expandToCapacity();
    return sp;
}

pub fn deinit(self: *StripedPattern, allocator: std.mem.Allocator) void {
    self.noise_3d.deinit(allocator);
    self.data.deinit(allocator);
    self.data = undefined;
    allocator.destroy(self);
}

fn logistic(height: f32) f32 {
    const width: f32 = 3.0;
    return (1.0 / (1.0 + std.math.pow(f32, 2.718, -width * height)));
}

pub fn fillData(self: *StripedPattern) void {
    const dims_f: f32 = @floatFromInt(self.dims);
    for (0..self.dims) |h| {
        const h_f: f32 = @floatFromInt(h);
        for (0..self.dims) |d| {
            const d_f: f32 = @floatFromInt(d);
            for (0..self.dims) |w| {
                const w_f: f32 = @floatFromInt(w);
                const dims_values: f32 = self.noise_3d.noise(h_f, d_f, w_f) / dims_f;

                var sine_val: f32 = logistic(@abs(@sin(dims_values * std.math.pi * self.freq * 8.0)));
                sine_val = @max(-1.0, @min(sine_val * 1.25 - 0.20, 1.0));

                const r_channel: f32 = 255.0 * sine_val;
                const g_channel: f32 = 255.0 * @min(sine_val * 1.5 - 0.25, 1.0);
                const b_channel: f32 = 255.0 * sine_val;

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
const math = @import("../../../../math/math.zig");
const noise = @import("../../../../noise/noise.zig");
