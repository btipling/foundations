data: std.ArrayListUnmanaged(u8) = .{},
dims: usize = 256,
dim: usize = 4,
noise_3d: *noise.Noise3D = undefined,

const StripedPattern = @This();

pub const max_tex_dims = 256;

pub fn init(allocator: std.mem.Allocator) *StripedPattern {
    var sp = allocator.create(StripedPattern) catch @panic("OOM");
    const n = noise.Noise3D.init(allocator);
    n.lacunarity = 2.0;
    n.gain = 0.5;
    n.octaves = 3;
    sp.* = .{
        .noise_3d = n,
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
    // const dims: f32 = @floatFromInt(self.dims);
    for (0..self.dims) |h| {
        const h_f: f32 = @floatFromInt(h);
        for (0..self.dims) |d| {
            const d_f: f32 = @floatFromInt(d);
            for (0..self.dims) |w| {
                const w_f: f32 = @floatFromInt(w);

                const nn: f32 = self.noise_3d.noise(h_f, d_f, w_f);

                const brightness: f32 = 1.0 - nn * 2.0;

                // std.debug.print("brightness {d} nn {d}\n", .{ brightness, nn });

                const r_channel: f32 = @max(brightness * 255.0, 0);
                const g_channel: f32 = @max(brightness * 255.0, 0);
                const b_channel: f32 = 255.0;

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
