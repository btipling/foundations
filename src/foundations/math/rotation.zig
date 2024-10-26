pub const Quat = vector.vec4;
pub const AxisAngle = struct {
    angle: f32,
    axis: vector.vec3,
};

pub fn axisAngleToQuat(a: AxisAngle) Quat {
    const half_angle = a.angle * 0.5;
    const w = @cos(half_angle);
    const nv = vector.normalize(a.axis);
    const v: vector.vec3 = vector.mul(@sin(half_angle), nv);
    return .{ w, v[0], v[1], v[2] };
}

test axisAngleToQuat {
    const a_q: Quat = axisAngleToQuat(.{
        .angle = degreesToRadians(90),
        .axis = .{ 1, 0, 0 },
    });
    const a_e: Quat = .{ 0.70710677, 0.70710677, 0, 0 };
    try std.testing.expectEqual(a_e, a_q);

    const b_q: Quat = axisAngleToQuat(.{
        .angle = degreesToRadians(90),
        .axis = .{ 0, 1, 0 },
    });
    const b_e: Quat = .{ 0.70710677, 0, 0.70710677, 0 };
    try std.testing.expectEqual(b_e, b_q);
}

pub fn quatToAngleAxis(q: Quat) AxisAngle {
    const w: f32 = q[0];
    const angle: f32 = 2.0 * std.math.acos(w);
    var axis: vector.vec3 = .{ q[1], q[2], q[3] };
    const v_len: f32 = @sqrt(1 - w * w);
    axis = vector.mul(1.0 / v_len, axis);
    return .{
        .angle = angle,
        .axis = axis,
    };
}

test quatToAngleAxis {
    const a_q: Quat = .{ 0.70710677, 0.70710677, 0, 0 };
    const a_expected_angle: f32 = degreesToRadians(90);
    const a_expected_axis: vector.vec3 = .{ 1, 0, 0 };
    const a_r: AxisAngle = quatToAngleAxis(a_q);
    try std.testing.expect(float.equal(a_expected_angle, a_r.angle, 0.00001));
    try std.testing.expect(float.equal(a_expected_axis[0], a_r.axis[0], 0.00001));
    try std.testing.expect(float.equal(a_expected_axis[1], a_r.axis[1], 0.00001));
    try std.testing.expect(float.equal(a_expected_axis[2], a_r.axis[2], 0.00001));
}

pub fn multiplyQuaternions(q2: Quat, q1: Quat) Quat {
    const v1: vector.vec3 = .{ q1[1], q1[2], q1[3] };
    const v2: vector.vec3 = .{ q2[1], q2[2], q2[3] };
    const w = q1[0] * q2[0] - vector.dotProduct(v1, v2);
    var v = vector.mul(q1[0], v2);
    v = vector.add(v, vector.mul(q2[0], v1));
    v = vector.add(v, vector.crossProduct(v2, v1));
    return .{ w, v[0], v[1], v[2] };
}

test multiplyQuaternions {
    const a_q: Quat = axisAngleToQuat(.{
        .angle = degreesToRadians(90),
        .axis = .{ 1, 0, 0 },
    });
    const a_e = a_q;
    const a_r = multiplyQuaternions(a_q, identityQuat());
    try std.testing.expectEqual(a_e, a_r);

    // (-sin(π) + 3i + 4j + 3k) × (4 + 3.9i -1j -3k) = 1.3 + 3 i + 36.7 j - 6.6 k
    const b_q1: Quat = .{ @sin(std.math.pi) * -1, 3, 4, 3 };
    const b_q2: Quat = .{ 4, 3.9, -1, -3 };
    const b_e: Quat = .{ 1.3, 3, 36.7, -6.6 };
    const b_r = multiplyQuaternions(b_q1, b_q2);
    try std.testing.expect(float.equal(b_e[0], b_r[0], 0.0001));
    try std.testing.expect(float.equal(b_e[1], b_r[1], 0.0001));
    try std.testing.expect(float.equal(b_e[2], b_r[2], 0.0001));
    try std.testing.expect(float.equal(b_e[3], b_r[3], 0.0001));

    // (sin(π) + 2i + 7j + 3k) × (1 -1i + 2.5j -4k) = -3.5 - 33.5 i + 12 j + 15 k
    const c_q1: Quat = .{ @sin(std.math.pi), 2, 7, 3 };
    const c_q2: Quat = .{ 1, -1, 2.5, -4 };
    const c_e: Quat = .{ -3.5, -33.5, 12, 15 };
    const c_r = multiplyQuaternions(c_q1, c_q2);
    try std.testing.expect(float.equal(c_e[0], c_r[0], 0.0001));
    try std.testing.expect(float.equal(c_e[1], c_r[1], 0.0001));
    try std.testing.expect(float.equal(c_e[2], c_r[2], 0.0001));
    try std.testing.expect(float.equal(c_e[3], c_r[3], 0.0001));
}

pub fn identityQuat() Quat {
    return .{ 1, 0, 0, 0 };
}

// AKA as the conjugate
pub fn inverseNormalizedQuat(q: Quat) Quat {
    return .{ q[0], -q[1], -q[2], -q[3] };
}

test inverseNormalizedQuat {
    const a_q1: Quat = .{ @sin(std.math.pi) * -1, 3, 4, 3 };
    const a_qn: Quat = vector.normalize(a_q1);
    const a_qi = inverseNormalizedQuat(a_qn);
    const a_e = identityQuat();
    const a_r = multiplyQuaternions(a_qn, a_qi);
    try std.testing.expect(float.equal(a_e[0], a_r[0], 0.0001));
    try std.testing.expect(float.equal(a_e[1], a_r[1], 0.0001));
    try std.testing.expect(float.equal(a_e[2], a_r[2], 0.0001));
    try std.testing.expect(float.equal(a_e[3], a_r[3], 0.0001));
}

pub fn inverseQuat(q: Quat) Quat {
    const l = vector.lengthSquared(q);
    return .{
        q[0] / l,
        -q[1] / l,
        -q[2] / l,
        -q[3] / l,
    };
}

test inverseQuat {
    const a_q1: Quat = .{ @sin(std.math.pi) * -1, 3, 4, 3 };
    const a_qi = inverseQuat(a_q1);
    const a_e = identityQuat();
    const a_r = multiplyQuaternions(a_q1, a_qi);
    try std.testing.expect(float.equal(a_e[0], a_r[0], 0.0001));
    try std.testing.expect(float.equal(a_e[1], a_r[1], 0.0001));
    try std.testing.expect(float.equal(a_e[2], a_r[2], 0.0001));
    try std.testing.expect(float.equal(a_e[3], a_r[3], 0.0001));
}

pub fn rotateVectorWithNormalizedQuat(v: vector.vec3, q: Quat) vector.vec3 {
    const qw = q[0];
    const qx = q[1];
    const qy = q[2];
    const qz = q[3];

    const vx = v[0];
    const vy = v[1];
    const vz = v[2];

    const v_mul: f32 = 2.0 * (qx * vx + qy * vy + qz * vz);
    const cross_mul: f32 = 2.0 * qw;
    const p_mul = cross_mul * qw - 1.0;

    return .{
        p_mul * vx + v_mul * qx + cross_mul * (qy * vz - qz * vy),
        p_mul * vy + v_mul * qy + cross_mul * (qz * vx - qx * vz),
        p_mul * vz + v_mul * qz + cross_mul * (qx * vy - qy * vx),
    };
}

test rotateVectorWithNormalizedQuat {
    const a_v1: vector.vec3 = .{ 1, 0, 0 };
    const a_q1: Quat = axisAngleToQuat(.{
        .angle = degreesToRadians(180),
        .axis = .{ 0, 1, 0 },
    });
    const a_qn = vector.normalize(a_q1);
    const a_e: vector.vec3 = .{ -1, 0, 0 };
    const a_r = rotateVectorWithNormalizedQuat(a_v1, a_qn);
    try std.testing.expect(float.equal(a_e[0], a_r[0], 0.0001));
    try std.testing.expect(float.equal(a_e[1], a_r[1], 0.0001));
    try std.testing.expect(float.equal(a_e[2], a_r[2], 0.0001));
}

pub fn radiansToDegrees(r: anytype) f32 {
    const T = @TypeOf(r);
    switch (@typeInfo(T)) {
        .float => return @floatCast(r * (180.0 / std.math.pi)),
        .comptime_float => return @floatCast(r * (180.0 / std.math.pi)),
        .int => {
            const rv: f32 = @floatFromInt(r);
            return rv * (180.0 / std.math.pi);
        },
        .comptime_int => {
            const rv: f32 = @floatFromInt(r);
            return rv * (180.0 / std.math.pi);
        },
        else => {},
    }
    @compileError("Input must be an integer or float");
}

test radiansToDegrees {
    try std.testing.expectEqual(90.0, radiansToDegrees(std.math.pi / 2.0));
}

pub fn degreesToRadians(d: anytype) f32 {
    const T = @TypeOf(d);
    switch (@typeInfo(T)) {
        .float => return @floatCast(d * (std.math.pi / 180.0)),
        .comptime_float => return @floatCast(d * (std.math.pi / 180.0)),
        .int => {
            const rv: f32 = @floatFromInt(d);
            return rv * (std.math.pi / 180.0);
        },
        .comptime_int => {
            const rv: f32 = @floatFromInt(d);
            return rv * (std.math.pi / 180.0);
        },
        else => {},
    }
    @compileError("Input must be an integer or float");
}

test degreesToRadians {
    try std.testing.expectEqual(std.math.pi * 2, degreesToRadians(360.0));
}

pub fn cartesian2DToPolarCoordinates(v: anytype) [2]f32 {
    const T = @TypeOf(v);
    const ti = @typeInfo(T);
    if (ti != .vector) @compileError("input must be a vector");
    if (ti.vector.len < 2) @compileError("input must be at least 2 dimensions");
    const child_type = @typeInfo(T).vector.child;
    if (@typeInfo(child_type) == .float or @typeInfo(child_type) == .comptime_float) {
        const x: f32 = @floatCast(v[0]);
        const y: f32 = @floatCast(v[1]);
        const angle: f32 = std.math.atan2(y, x);
        const r: f32 = @sqrt(x * x + y * y);
        return .{ r, angle };
    }
    if (@typeInfo(child_type) == .It or @typeInfo(child_type) == .comptime_int) {
        const x: f32 = @floatFromInt(v[0]);
        const y: f32 = @floatFromInt(v[1]);
        const angle: f32 = std.math.atan2(y, x);
        const r: f32 = @sqrt(x * x + y * y);
        return .{ r, angle };
    }
    @compileError("input must be a vector of floats or ints");
}

test cartesian2DToPolarCoordinates {
    const a_v1: vector.vec2 = .{ 1, 1 };
    const a_v2: vector.vec2 = vector.normalize(a_v1);
    const a_coords = cartesian2DToPolarCoordinates(a_v2);
    try std.testing.expect(float.equal(1.0, a_coords[0], 0.0001));
    try std.testing.expectEqual(45.0, radiansToDegrees(a_coords[1]));
}

pub fn polarCoordinatesToCartesian2D(comptime T: type, coords: [2]f32) T {
    const ti = @typeInfo(T);
    if (ti != .vector) @compileError("return type must be a vector");
    if (ti.vector.len < 2) @compileError("return type must be at least 2 dimensions");
    const child_type = @typeInfo(T).vector.child;
    if (@typeInfo(child_type) == .float or @typeInfo(child_type) == .comptime_float) {
        const r: f32 = coords[0];
        const angle: f32 = coords[1];
        const x: f32 = r * @cos(angle);
        const y: f32 = r * @sin(angle);
        var res: T = std.mem.zeroes(T);
        res[0] = x;
        res[1] = y;
        return res;
    }
    if (@typeInfo(child_type) == .It or @typeInfo(child_type) == .comptime_int) {
        const r: f32 = coords[0];
        const angle: f32 = coords[1];
        const x: f32 = r * @cos(angle);
        const y: f32 = r * @sin(angle);
        var res: T = std.mem.zeroes(T);
        res[0] = @intFromFloat(x);
        res[1] = @intFromFloat(y);
        return res;
    }
    @compileError("return type must be a vector of floats or ints");
}

test polarCoordinatesToCartesian2D {
    const a_v1: vector.vec2 = .{ 1, 1 };
    const a_v2: vector.vec2 = vector.normalize(a_v1);
    const a_coords: [2]f32 = .{ 1, degreesToRadians(45) };
    const a_res = polarCoordinatesToCartesian2D(vector.vec2, a_coords);
    try std.testing.expect(float.equal(a_v2[0], a_res[0], 0.0001));
    try std.testing.expect(float.equal(a_v2[1], a_res[1], 0.0001));
}

pub fn cartesian3DToSphericalCoordinates(v: anytype) [3]f32 {
    const T = @TypeOf(v);
    const ti = @typeInfo(T);
    if (ti != .vector) @compileError("input must be a vector");
    if (ti.vector.len < 3) @compileError("input must be at least 3 dimensions");
    const child_type = @typeInfo(T).vector.child;
    if (@typeInfo(child_type) == .float or @typeInfo(child_type) == .comptime_float) {
        const x: f32 = @floatCast(v[0]);
        const y: f32 = @floatCast(v[1]);
        const z: f32 = @floatCast(v[2]);
        const p: f32 = @sqrt(x * x + y * y + z * z);
        const r: f32 = @sqrt(x * x + y * y);
        const z_angle: f32 = std.math.atan2(r, z);
        const angle: f32 = std.math.atan2(y, x);
        return .{ p, z_angle, angle };
    }
    if (@typeInfo(child_type) == .It or @typeInfo(child_type) == .comptime_int) {
        const x: f32 = @floatFromInt(v[0]);
        const y: f32 = @floatFromInt(v[1]);
        const z: f32 = @floatFromInt(v[2]);
        const p: f32 = @sqrt(x * x + y * y + z * z);
        const r: f32 = @sqrt(x * x + y * y);
        const z_angle: f32 = std.math.atan2(r, z);
        const angle: f32 = std.math.atan2(y, x);
        return .{ p, z_angle, angle };
    }
    @compileError("input must be a vector of floats or ints");
}

test cartesian3DToSphericalCoordinates {
    const a_v1: vector.vec3 = .{ 1, 1, 1 };
    const a_v2: vector.vec3 = vector.normalize(a_v1);
    const a_coords = cartesian3DToSphericalCoordinates(a_v2);
    const expecte_z_angle = radiansToDegrees(std.math.acos(@as(f32, 1.0 / @sqrt(3.0))));
    try std.testing.expect(float.equal(1.0, a_coords[0], 0.0001));
    try std.testing.expect(float.equal(expecte_z_angle, radiansToDegrees(a_coords[1]), 0.0001));
    try std.testing.expectEqual(45.0, radiansToDegrees(a_coords[2]));
}

pub fn sphericalCoordinatesToCartesian3D(comptime T: type, coords: [3]f32) T {
    const ti = @typeInfo(T);
    if (ti != .vector) @compileError("return type must be a vector");
    if (ti.vector.len < 3) @compileError("return type must be at least 3 dimensions");
    const child_type = @typeInfo(T).vector.child;
    if (@typeInfo(child_type) == .float or @typeInfo(child_type) == .comptime_float) {
        const p: f32 = coords[0];
        const angle_z: f32 = coords[1];
        const angle: f32 = coords[2];
        const x: f32 = p * @sin(angle_z) * @cos(angle);
        const y: f32 = p * @sin(angle_z) * @sin(angle);
        const z: f32 = p * @cos(angle_z);

        var res: T = std.mem.zeroes(T);
        res[0] = x;
        res[1] = y;
        res[2] = z;
        return res;
    }
    if (@typeInfo(child_type) == .It or @typeInfo(child_type) == .comptime_int) {
        const p: f32 = coords[0];
        const angle_z: f32 = coords[1];
        const angle: f32 = coords[2];
        const x: f32 = p * @sin(angle_z) * @cos(angle);
        const y: f32 = p * @sin(angle_z) * @sin(angle);
        const z: f32 = p * @cos(angle_z);

        var res: T = std.mem.zeroes(T);
        res[0] = @intFromFloat(x);
        res[1] = @intFromFloat(y);
        res[2] = @intFromFloat(z);
        return res;
    }
    @compileError("return type must be a vector of floats or ints");
}

test sphericalCoordinatesToCartesian3D {
    const a_v1: vector.vec3 = .{ 1, 1, 1 };
    const a_v2: vector.vec3 = vector.normalize(a_v1);
    const z_angle: f32 = std.math.acos(@as(f32, 1.0 / @sqrt(3.0)));
    const a_coords: [3]f32 = .{ 1, z_angle, degreesToRadians(45) };
    const a_res = sphericalCoordinatesToCartesian3D(vector.vec3, a_coords);
    try std.testing.expect(float.equal(a_v2[0], a_res[0], 0.0001));
    try std.testing.expect(float.equal(a_v2[1], a_res[1], 0.0001));
    try std.testing.expect(float.equal(a_v2[2], a_res[2], 0.0001));
}

const std = @import("std");
const vector = @import("vector.zig");
const float = @import("float.zig");
