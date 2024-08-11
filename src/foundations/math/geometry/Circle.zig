center: vector.vec2,
radius: f32,

const Circle = @This();

const default_epsilon: f32 = 0.0001;

pub fn parametricCircle(self: Circle, t: f32) vector.vec2 {
    return .{
        @cos(2 * std.math.pi * t) * self.radius,
        @sin(2 * std.math.pi * t) * self.radius,
    };
}

pub fn implicitCircle(self: Circle, point: vector.vec2, epsilon: ?f32) bool {
    const e = epsilon orelse default_epsilon;
    const x = point[0] - self.center[0];
    const y = point[1] - self.center[1];
    return float.equal(x * x + y * y, self.radius * self.radius, e);
}

pub fn withinCircle(self: Circle, point: vector.vec2) bool {
    const x = point[0] - self.center[0];
    const y = point[1] - self.center[1];
    return x * x + y * y <= self.radius * self.radius;
}

const std = @import("std");
const vector = @import("../vector.zig");
const float = @import("../float.zig");
