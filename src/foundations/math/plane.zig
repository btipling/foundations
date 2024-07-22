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

// isValid - p1 and p2 are points in the plane
pub fn isValid(self: Plane, p1: vector.vec3, p2: vector.vec3) bool {
    return float.equal(vector.dotProduct(self.normal, (vector.sub(p1, p2))), 0.00001);
}

const vector = @import("vector.zig");
const float = @import("float.zig");
