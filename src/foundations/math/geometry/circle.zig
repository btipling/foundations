const default_epsilon: f32 = 0.0001;

pub fn parametricCircle(t: f32) vector.vec2 {
    return .{
        @cos(2 * std.math.pi * t),
        @sin(2 * std.math.pi * t),
    };
}

pub fn implicitCircle(center: vector.vec2, radius: f32, point: vector.vec2, epsilon: ?f32) bool {
    const e = epsilon orelse default_epsilon;
    const x = point[0] - center[0];
    const y = point[1] - center[1];
    return float.equal(x * x + y * y, radius * radius, e);
}

pub fn withinCircle(center: vector.vec2, radius: f32, point: vector.vec2) bool {
    const x = point[0] - center[0];
    const y = point[1] - center[1];
    return x * x + y * y <= radius * radius;
}

const std = @import("std");
const vector = @import("../vector.zig");
const float = @import("../float.zig");
