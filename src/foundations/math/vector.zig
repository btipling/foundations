pub const vec4 = @Vector(4, f32);
pub const vec3 = @Vector(3, f32);
pub const vec2 = @Vector(2, f32);

pub fn negate(v: anytype) @TypeOf(v) {
    return mul(-1, v);
}

test negate {
    const a: vec4 = .{ 1, 2, 3, 0 };
    const ae: vec4 = .{ -1, -2, -3, 0 };
    try std.testing.expectEqual(ae, negate(a));
}

pub fn mul(m: anytype, v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const K = @TypeOf(m);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Float, .Int, .ComptimeFloat, .ComptimeInt => return v * @as(T, @splat(m)),
            // This isn't mathmatically correct for vector math, correct vector multiplication is the dot product or the cross product
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector length") else return v * m,
            else => @compileError("second input must be a vector or scalar"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test mul {
    const a: vec4 = .{ 1, 2, 3, 0 };
    const ae: vec4 = .{ 2, 4, 6, 0 };
    try std.testing.expectEqual(ae, mul(2, a));
    const b: vec4 = .{ 1, 2, 3, 0 };
    const be: vec4 = .{ 10, -20, 9, 0 };
    try std.testing.expectEqual(be, mul(@as(vec4, .{ 10, -10, 3, 100 }), b));
}

pub fn div(v: anytype, d: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const K = @TypeOf(d);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Float, .Int, .ComptimeFloat, .ComptimeInt => return v / @as(T, @splat(d)),
            // This isn't mathmatically correct for vector math, vectors can't be divided by other vectors
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector dimension") else return v / d,
            else => @compileError("second input must be a vector or scalar"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test div {
    const a: vec4 = .{ 2, 4, 6, 0 };
    const ae: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(ae, div(a, 2));
    const b: vec4 = .{ 10, -20, 9, 0 };
    const be: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(be, div(b, @as(vec4, .{ 10, -10, 3, 100 })));
}

pub fn add(v1: anytype, v2: anytype) @TypeOf(v1) {
    const T = @TypeOf(v1);
    const K = @TypeOf(v2);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            // This isn't mathmatically correct for vector math, vectors and scalars cannot be added together
            .Float, .Int, .ComptimeFloat, .ComptimeInt => return v1 + @as(T, @splat(v2)),
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector dimension") else return v1 + v2,
            else => @compileError("second input must be a vector or scalar"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test add {
    const a: vec4 = .{ 1, 2, 3, 0 };
    const ae: vec4 = .{ 3, 4, 5, 2 };
    try std.testing.expectEqual(ae, add(a, 2));
    const b: vec4 = .{ 1, 2, 3, 0 };
    const be: vec4 = .{ 10, -20, 9, 0 };
    try std.testing.expectEqual(be, add(@as(vec4, .{ 9, -22, 6, 0 }), b));
}

pub fn sub(v1: anytype, v2: anytype) @TypeOf(v1) {
    const T = @TypeOf(v1);
    const K = @TypeOf(v2);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            // This isn't mathmatically correct for vector math, vectors and scalars cannot be subtracted
            .Float, .Int, .ComptimeFloat, .ComptimeInt => return v1 - @as(T, @splat(v2)),
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector dimension") else return v1 - v2,
            else => @compileError("second input must be a vector or scalar"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test sub {
    const a: vec4 = .{ 2, 4, 6, 0 };
    const ae: vec4 = .{ 0, 2, 4, -2 };
    try std.testing.expectEqual(ae, sub(a, 2));
    const b: vec4 = .{ 10, -20, 9, 0 };
    const be: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(be, sub(b, @as(vec4, .{ 9, -22, 6, 0 })));
}

// vecFromPointAToPointB treats points as vectors from origin
pub fn vecFromPointAToPointB(v1: anytype, v2: anytype) @TypeOf(v1) {
    const T = @TypeOf(v1);
    const K = @TypeOf(v2);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector dimension") else return v2 - v1,
            else => @compileError("second input must be a vector"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test vecFromPointAToPointB {
    const b: vec4 = .{ 10, -20, 9, 0 };
    const be: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(be, vecFromPointAToPointB(@as(vec4, .{ 9, -22, 6, 0 }), b));
}

pub fn magnitude(v: anytype) @TypeOf(v[0]) {
    switch (@typeInfo(@TypeOf(v))) {
        .Vector => {
            return @sqrt(@reduce(.Add, v * v));
        },
        else => {},
    }
    @compileError("input must be a vector");
}

test magnitude {
    const a: vec4 = .{ 3, 4, 5, 6 };
    const ae: f32 = 9.27361;
    try std.testing.expect(float.equal(ae, magnitude(a), 0.00001));
}

pub fn normalize(v: anytype) @TypeOf(v) {
    if (@typeInfo(@TypeOf(v)) != .Vector) @compileError("input must be a vector");
    return div(v, magnitude(v));
}

test normalize {
    const a: vec2 = .{ 12, -5 };
    const aex: f32 = 0.923;
    const aey: f32 = -0.385;
    const res = normalize(a);
    try std.testing.expect(float.equal(aex, res[0], 0.001));
    try std.testing.expect(float.equal(aey, res[1], 0.001));
}

pub fn distance(a: anytype, b: anytype) @TypeOf(a[0]) {
    return magnitude(sub(b, a));
}

test distance {
    const a_a: vec2 = .{ 5, 0 };
    const a_b: vec2 = .{ -1, 8 };
    const ae: f32 = 10;
    try std.testing.expectEqual(ae, distance(a_a, a_b));
    try std.testing.expectEqual(ae, distance(a_b, a_a));
}

pub fn dotProduct(v1: anytype, v2: anytype) @TypeOf(v1[0]) {
    const T = @TypeOf(v1);
    const K = @TypeOf(v2);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector dimension") else return @reduce(.Add, v1 * v2),
            else => @compileError("second input must be a vector"),
        },
        else => {},
    }
    @compileError("first input must be a vector");
}

test dotProduct {
    const a_v1: vec2 = .{ 4, 6 };
    const a_v2: vec2 = .{ -3, 7 };
    const ae: f32 = 30;
    try std.testing.expectEqual(ae, dotProduct(a_v1, a_v2));

    const b_v1: vec3 = .{ 3, -2, 7 };
    const b_v2: vec3 = .{ 0, 4, -1 };
    const be: f32 = -15;
    try std.testing.expectEqual(be, dotProduct(b_v1, b_v2));

    // Geometric tests
    // perpendicular dot product produces a 0:
    const c_v1: vec3 = .{ 2, 0, 0 };
    const c_v2: vec3 = .{ 0, 4, 0 };
    const ce: f32 = 0;
    try std.testing.expectEqual(ce, dotProduct(c_v1, c_v2));

    // same direction vectors produce a positive value
    const d_v1: vec3 = .{ 2, 0, 0 };
    const d_v2: vec3 = .{ 4, 0, 0 };
    try std.testing.expect(dotProduct(d_v1, d_v2) > 0);

    // opposite direction vectors produce a negative value
    const e_v1: vec3 = .{ 2, 0, 0 };
    const e_v2: vec3 = .{ -4, 0, 0 };
    try std.testing.expect(dotProduct(e_v1, e_v2) < 0);
}

const std = @import("std");
const float = @import("float.zig");