dims: usize = 256,
data: std.ArrayListUnmanaged(f32) = .{},
rand: std.Random.DefaultPrng = undefined,
lacunarity: f32 = 2.0,
gain: f32 = 0.6,
octaves: u32 = 6,

const Noise3D = @This();

// Makes noise in 3D
pub fn init(allocator: std.mem.Allocator) *Noise3D {
    var n = allocator.create(Noise3D) catch @panic("OOM");
    errdefer allocator.destroy(n);

    n.* = .{};
    n.data = std.ArrayListUnmanaged(f32).initCapacity(
        allocator,
        n.dims * n.dims * n.dims,
    ) catch @panic("OOM");
    n.data.expandToCapacity();
    return n;
}

pub fn deinit(self: *Noise3D, allocator: std.mem.Allocator) void {
    self.data.deinit(allocator);
    self.data = undefined;
    allocator.destroy(self);
}

pub fn noise(self: *Noise3D, fx: f32, fy: f32, fz: f32) f32 {
    const rv = c.stb_perlin_turbulence_noise3(
        fx * 0.03,
        fy * 0.03,
        fz * 0.03,
        self.lacunarity,
        self.gain,
        @intCast(self.octaves),
    );
    if (rv > 0) {
        // std.debug.print("rv: {d}\n", .{rv});
    }
    return rv;
}

const std = @import("std");
const c = @import("../c.zig").c;
