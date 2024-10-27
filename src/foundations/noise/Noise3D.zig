dims: usize = 256,
data: std.ArrayListUnmanaged = .{},
rand: std.Random.DefaultPrng = undefined,

const Noise3D = @This();

// Makes noise in 3D
pub fn init(allocator: std.mem.Allocator) *Noise3D {
    var n = allocator.create(Noise3D) catch @panic("OOM");
    errdefer allocator.destroy(n);

    const prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        std.posix.getrandom(std.mem.asBytes(&seed)) catch @panic("random fail");
        break :blk seed;
    });

    n.* = .{
        .rand = prng,
    };
    n.data = std.ArrayListUnmanaged(u8).initCapacity(
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

pub fn makeSomeNoise(self: *Noise3D) void {
    const dims = self.dims;
    for (0..dims) |h| {
        for (0..dims) |d| {
            for (0..dims) |w| {
                const i: usize = self.indexAt(h, d, w);
                self.data[i] = self.rand.random().float(f32);
            }
        }
    }
}

pub fn indexAt(self: *Noise3D, h: usize, d: usize, w: usize) usize {
    const dims = self.dims;
    return @mod(h, dims) + @mod(d, dims) * d + @mod(w, dims) * dims * dims;
}
pub fn indexAtF(self: *Noise3D, h: f32, d: f32, w: f32) usize {
    return self.indexAt(@intFromFloat(h), @intFromFloat(d), @intFromFloat(w));
}

// comp - get the compliment
fn comp(v: f32) f32 {
    return 1.0 - v;
}

fn shift(self: *Noise3D, v: f32, zoom: f32) f32 {
    const dims: f32 = @floatFromInt(self.dims);
    var nv = v - 1.0;
    if (nv < 0) {
        nv = @round(dims / zoom) - 1.0;
    }
    return nv;
}

pub fn interpolateNoise(self: *Noise3D, zoom: f32, h1: f32, d1: f32, w1: f32) f32 {
    const h_f = h1 - @floor(h1);
    const d_f = d1 - @floor(d1);
    const z_f = w1 - @floor(w1);

    const h2 = shift(h1, zoom);
    const d2 = shift(d1, zoom);
    const w2 = shift(w1, zoom);

    var value: f32 = 0.0;
    value += h_f * d_f * z_f * self.data.items[self.indexAtF(h1, d1, w1)];
    value += comp(h_f) * d_f * z_f * self.data.items[self.indexAtF(h2, d1, w1)];
    value += h_f * comp(d_f) * z_f * self.data.items[self.indexAtF(h1, d2, w1)];
    value += comp(h_f) * comp(d_f) * z_f * self.data.items[self.indexAtF(h2, d2, w1)];

    value += h_f * d_f * comp(z_f) * self.data.items[self.indexAtF(h1, d1, w2)];
    value += comp(h_f) * d_f * comp(z_f) * self.data.items[self.indexAtF(h2, d1, w2)];
    value += h_f * comp(d_f) * comp(z_f) * self.data.items[self.indexAtF(h1, d2, w2)];
    value += comp(h_f) * comp(d_f) * comp(z_f) * self.data.items[self.indexAtF(h2, d2, w2)];
    return value;
}

pub fn turbulence(self: *Noise3D, x: f32, y: f32, z: f32, max_zoom: f32) f32 {
    var sum: f32 = 0.0;
    var zoom: f32 = max_zoom;
    while (zoom >= 0.9) {
        sum = sum + self.interpolateNoise(zoom, x / zoom, y / zoom, z / zoom) * zoom;
        zoom = zoom / 2.0;
    }
    sum = self.dims / 2.0 * sum / max_zoom;
    return sum;
}

const std = @import("std");
