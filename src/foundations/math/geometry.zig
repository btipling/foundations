pub fn parametricCircle(t: f32) vector.vec2 {
    return .{
        @cos(2 * std.math.pi * t),
        @sin(2 * std.math.pi * t),
    };
}

const default_epsilon: f32 = 0.0001;

pub fn implicitCircle(v: vector.vec2, epsilon: ?f32) bool {
    const e = epsilon orelse default_epsilon;
    return float.equal(v[0] * v[0] + v[1] * v[1], 1.0, e);
}

const std = @import("std");
const vector = @import("vector.zig");
const float = @import("float.zig");
