data: std.ArrayListUnmanaged(u8) = .{},
dims: usize = 256,
dim: usize = 4,
noise_3d: *noise.Noise3D = undefined,

const Static = @This();

pub const max_tex_dims = 256;

pub fn init(allocator: std.mem.Allocator) *Static {
    var sp = allocator.create(Static) catch @panic("OOM");
    const n = noise.Noise3D.init(allocator);
    n.coord_sensitivity = 0.8;
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

pub fn deinit(self: *Static, allocator: std.mem.Allocator) void {
    self.noise_3d.deinit(allocator);
    self.data.deinit(allocator);
    self.data = undefined;
    allocator.destroy(self);
}

fn wave(self: *Static, h_f: f32, d_f: f32, w_f: f32) f32 {
    var sum: f32 = 0.0;
    const pers: f32 = 0.5;
    var amp: f32 = 10.0;
    self.noise_3d.coord_sensitivity = 0.01;
    for (0..3) |octaves| {
        self.noise_3d.octaves = @intCast(octaves + 1);
        const n: f32 = self.noise_3d.turbulence(h_f, d_f, w_f);
        sum += n * amp;

        self.noise_3d.coord_sensitivity *= 2.0;
        amp *= pers;
    }
    return @sin(sum * std.math.pi);
}

pub fn fillData(self: *Static) void {
    for (0..self.dims) |h| {
        const h_f: f32 = @floatFromInt(h);
        for (0..self.dims) |d| {
            const d_f: f32 = @floatFromInt(d);
            for (0..self.dims) |w| {
                const w_f: f32 = @floatFromInt(w);
                self.noise_3d.lacunarity = 2.0;
                // self.noise_3d.octaves = 3;
                // self.noise_3d.coord_sensitivity = @mod(w_f, 12.8732) * @mod(h_f, 49.3283) * 0.01;
                self.noise_3d.gain = 0.05;
                const nn: f32 = self.wave(h_f, d_f, w_f);

                const brightness: f32 = nn;

                const r_channel: f32 = @min(@max(brightness * 255.0, 0), 5.0);
                const g_channel: f32 = @min(@max(brightness * 255.0, 0), 5.0);
                const b_channel: f32 = @min(@max(brightness * 255.0, 0), 5.0);

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
