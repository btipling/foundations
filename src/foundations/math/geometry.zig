pub fn parametricCircle(t: f32) vector.vec2 {
    return .{
        @cos(2 * std.math.pi * t),
        @sin(2 * std.math.pi * t),
    };
}

pub fn implicitCircle(v: vector.vec2) bool {
    return float.equal(v[0] * v[0] + v[1] * v[1], 1.0, 0.0001);
}

const std = @import("std");
const vector = @import("vector.zig");
const float = @import("float.zig");
