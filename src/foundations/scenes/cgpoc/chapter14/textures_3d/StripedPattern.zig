data: []u8,
width: usize = 256,
height: usize = 256,
depth: usize = 256,
dim: usize = 4,
primary_color: math.vector.vec4 = .{ 255, 255, 0, 255 },
secondary_color: math.vector.vec4 = .{ 0, 0, 255, 255 },
tex_3d_pattern: [][][]f32,

const StripedPattern = @This();

pub fn buildPattern(self: StripedPattern) void {
    for (0..self.width) |w| {
        for (0..self.height) |h| {
            for (0..self.depth) |d| {
                const h_f: f32 = @floatFromInt(h);
                if (math.float.equal_e(@mod(h_f / 10.0, 2), 0.0)) {
                    self.tex_3d_pattern[w][h][d] = 0.0;
                } else {
                    self.tex_3d_pattern[w][h][d] = 1.0;
                }
            }
        }
    }
}

pub fn fillData(self: StripedPattern) void {
    for (0..self.width) |w| {
        for (0..self.height) |h| {
            for (0..self.depth) |d| {
                var color: math.vector.vec4 = self.secondary_color;
                if (math.float.equal_e(self.tex_3d_pattern[w][h][d], 1.0)) {
                    color = self.primary_color;
                }
                var i = w;
                i *= self.width * self.height * self.dim;
                i += h * self.height * self.dim;
                i += d * self.dim;
                self.data[i + 0] = color[0];
                self.data[i + 1] = color[1];
                self.data[i + 2] = color[2];
                self.data[i + 3] = color[3];
            }
        }
    }
}

const math = @import("../../../../math/math.zig");
