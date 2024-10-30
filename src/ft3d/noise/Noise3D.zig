dims: usize = 256,
data: std.ArrayListUnmanaged(f32) = .{},
coord_sensitivity: f32 = 0.03,
rand: std.Random.DefaultPrng = undefined,
lacunarity: f32 = 2.0,
gain: f32 = 0.6,
offset: f32 = 2.0,
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

pub fn turbulence(self: *Noise3D, fx: f32, fy: f32, fz: f32) f32 {
    const rv = c.stb_perlin_turbulence_noise3(
        fx * self.coord_sensitivity,
        fy * self.coord_sensitivity,
        fz * self.coord_sensitivity,
        self.lacunarity,
        self.gain,
        @intCast(self.octaves),
    );
    return rv;
}

pub fn fbm(self: *Noise3D, fx: f32, fy: f32, fz: f32) f32 {
    const rv = c.stb_perlin_fbm_noise3(
        fx * self.coord_sensitivity,
        fy * self.coord_sensitivity,
        fz * self.coord_sensitivity,
        self.lacunarity,
        self.gain,
        @intCast(self.octaves),
    );
    return rv;
}

pub fn ridged(self: *Noise3D, fx: f32, fy: f32, fz: f32) f32 {
    const rv = c.stb_perlin_ridge_noise3(
        fx * self.coord_sensitivity,
        fy * self.coord_sensitivity,
        fz * self.coord_sensitivity,
        self.lacunarity,
        self.gain,
        self.offset,
        @intCast(self.octaves),
    );
    return rv;
}

pub fn perlin(self: *Noise3D, fx: f32, fy: f32, fz: f32, x_wrap: c_int, y_wrap: c_int, z_wrap: c_int) f32 {
    const rv = c.stb_perlin_noise3(
        fx * self.coord_sensitivity,
        fy * self.coord_sensitivity,
        fz * self.coord_sensitivity,
        x_wrap,
        y_wrap,
        z_wrap,
    );
    return rv;
}

const std = @import("std");
const c = @import("../c.zig").c;
