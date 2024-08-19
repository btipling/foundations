normal: vector.vec3,
offset: f32,
parameterized: vector.vec4,

const PlaneError = error{Invalid};

const Plane = @This();

pub fn init(normal: vector.vec3, offset: f32) Plane {
    return .{
        .normal = normal,
        .offset = offset,
        .parameterized = .{ normal[0], normal[1], normal[2], offset },
    };
}

pub fn initFromPoints(p1: vector.vec3, p2: vector.vec3, p3: vector.vec3) PlaneError!Plane {
    const e3 = vector.sub(p2, p1);
    const e1 = vector.sub(p3, p2);
    const vp = vector.crossProduct(e3, e1);
    if (vector.isZeroVector(vp)) return PlaneError.Invalid;
    const n = vector.normalize(vp);
    const d = vector.dotProduct(n, p1);
    return init(n, d);
}

pub fn bestFitFromPoints(points: []vector.vec3) PlaneError!Plane {
    if (points.len < 3) return PlaneError.Invalid;
    var result: vector.vec3 = .{ 0, 0, 0 };
    var i: usize = 0;
    while (i < points.len - 1) : (i += 1) {
        const p = points[i];
        const c = points[i + 1];
        result[0] += p[2] + c[2] * p[1] - c[1];
        result[1] += p[0] + c[0] * p[2] - c[2];
        result[2] += p[1] + c[1] * p[0] - c[0];
    }
    const n = vector.normalize(result);
    const d = vector.dotProduct(n, points[0]);
    return init(n, d);
}

// isValid - p1 and p2 are points in the plane
pub fn isValid(self: Plane, p1: vector.vec3, p2: vector.vec3) bool {
    return float.equal(vector.dotProduct(self.normal, (vector.sub(p1, p2))), 0.00001);
}

pub fn distanceToPoint(self: Plane, q: vector.vec3) f32 {
    return vector.dotProduct(q, self.normal) - self.offset;
}

pub fn closestPointToOrigin(self: Plane) vector.vec4 {
    const v = vector.mul(-self.offset, self.normal);
    const w = vector.lengthSquared(self.normal);
    return .{ v[0], v[1], v[2], w };
}

pub fn closestPointToPoint(self: Plane, p: vector.vec4) vector.vec4 {
    const q = vector.mul(vector.dotProduct(self.parameterized, p), vector.vec3ToVec4Vector(self.normal));
    return vector.sub(p, q);
}

pub fn debug(self: Plane) void {
    std.debug.print("plane: ({d}, {d}, {d}| {d})\n", .{
        self.parameterized[0],
        self.parameterized[1],
        self.parameterized[2],
        self.parameterized[3],
    });
}

const std = @import("std");
const vector = @import("../vector.zig");
const float = @import("../float.zig");
