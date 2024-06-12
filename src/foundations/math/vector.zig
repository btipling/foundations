pub const vec4 = @Vector(4, f32);

pub fn negate(v: anytype) @TypeOf(v) {
    return mul(-1, v);
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

test negate {
    const a: vec4 = .{ 1, 2, 3, 0 };
    const ae: vec4 = .{ -1, -2, -3, 0 };
    try std.testing.expectEqual(ae, negate(a));
}

test mul {
    const a: vec4 = .{ 1, 2, 3, 0 };
    const ae: vec4 = .{ 2, 4, 6, 0 };
    try std.testing.expectEqual(ae, mul(2, a));
    const b: vec4 = .{ 1, 2, 3, 0 };
    const be: vec4 = .{ 10, -20, 9, 0 };
    try std.testing.expectEqual(be, mul(@as(vec4, .{ 10, -10, 3, 100 }), b));
}

test div {
    const a: vec4 = .{ 2, 4, 6, 0 };
    const ae: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(ae, div(a, 2));
    const b: vec4 = .{ 10, -20, 9, 0 };
    const be: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(be, div(b, @as(vec4, .{ 10, -10, 3, 100 })));
}

test add {
    const a: vec4 = .{ 1, 2, 3, 0 };
    const ae: vec4 = .{ 3, 4, 5, 2 };
    try std.testing.expectEqual(ae, add(a, 2));
    const b: vec4 = .{ 1, 2, 3, 0 };
    const be: vec4 = .{ 10, -20, 9, 0 };
    try std.testing.expectEqual(be, add(@as(vec4, .{ 9, -22, 6, 0 }), b));
}

test sub {
    const a: vec4 = .{ 2, 4, 6, 0 };
    const ae: vec4 = .{ 0, 2, 4, -2 };
    try std.testing.expectEqual(ae, sub(a, 2));
    const b: vec4 = .{ 10, -20, 9, 0 };
    const be: vec4 = .{ 1, 2, 3, 0 };
    try std.testing.expectEqual(be, sub(b, @as(vec4, .{ 9, -22, 6, 0 })));
}

const std = @import("std");
