center: vector.vec3,
radius: f32,

const Sphere = @This();

const default_epsilon: f32 = 0.0001;

pub fn implicitSphere(self: Sphere, point: vector.vec3, epsilon: ?f32) bool {
    const e = epsilon orelse default_epsilon;
    const x = point[0] - self.center[0];
    const y = point[1] - self.center[1];
    const z = point[2] - self.center[2];
    return float.equal(
        x * x + y * y + z * z,
        self.radius * self.radius,
        e,
    );
}

pub fn withinSphere(self: Sphere, point: vector.vec3) bool {
    const x = point[0] - self.center[0];
    const y = point[1] - self.center[1];
    const z = point[2] - self.center[2];
    return x * x + y * y + z * z <= self.radius * self.radius;
}

const std = @import("std");
const vector = @import("../vector.zig");
const float = @import("../float.zig");
