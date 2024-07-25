const default_epsilon: f32 = 0.0001;

pub fn implicitSphere(center: vector.vec3, radius: f32, point: vector.vec3, epsilon: ?f32) bool {
    const e = epsilon orelse default_epsilon;
    const x = point[0] - center[0];
    const y = point[1] - center[1];
    const z = point[2] - center[2];
    return float.equal(
        x * x + y * y + z * z,
        radius * radius,
        e,
    );
}

pub fn withinSphere(center: vector.vec3, radius: f32, point: vector.vec3) bool {
    const x = point[0] - center[0];
    const y = point[1] - center[1];
    const z = point[2] - center[2];
    return x * x + y * y + z * z <= radius * radius;
}

const std = @import("std");
const vector = @import("../vector.zig");
const float = @import("../float.zig");
