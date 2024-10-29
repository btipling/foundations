data: std.ArrayListUnmanaged(u8) = .{},
dims: usize = 256,
dim: usize = 4,
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

pub fn fillData(self: *StripedPattern) void {
    const period: f32 = 40.0;
    const offset: f32 = 2.0;
    const dims: f32 = @floatFromInt(self.dims);
    for (0..self.dims) |h| {
        const h_f: f32 = @floatFromInt(h);
        for (0..self.dims) |d| {
            const d_f: f32 = @floatFromInt(d);
            for (0..self.dims) |w| {
                const w_f: f32 = @floatFromInt(w);

                // double xValue = (i - (double)noiseWidth / 2.0) / (double)noiseWidth;
                // double yValue = (j - (double)noiseHeight / 2.0) / (double)noiseHeight;
                // double distanceFromZ = sqrt(xValue * xValue + yValue * yValue) + turbPower * turbulence(i,j,k,maxZoom)/256.0;
                // double sineValue = 128.0 * abs(sin(2.0 * xyPeriod * distanceFromZ * 3.14159));

                // float redPortion = (float)(80 + (int)sineValue);
                // float greenPortion = (float)(30 + (int)sineValue);
                // float bluePortion = 0.0f;

                const nn: f32 = self.noise_3d.noise(h_f, d_f, w_f) / dims;

                const w_val: f32 = ((w_f - dims / offset) / dims) - 0.25;
                const h_val: f32 = ((h_f - dims / offset) / dims) - 0.25;
                const depth_dist: f32 = @sqrt(w_val * w_val + h_val * h_val) + nn * 3.0;
                const sine_val = (dims / offset * @abs(@sin(offset * period * depth_dist * std.math.pi))) / dims * 2;

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
const noise = @import("noise/noise.zig");
