pub fn radiansToDegrees(r: anytype) f32 {
    const T = @TypeOf(r);
    switch (@typeInfo(T)) {
        .Float => return @floatCast(r * (180.0 / std.math.pi)),
        .ComptimeFloat => return @floatCast(r * (180.0 / std.math.pi)),
        .Int => {
            const rv: f32 = @floatFromInt(r);
            return rv * (180.0 / std.math.pi);
        },
        .ComptimeInt => {
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
        .Float => return @floatCast(d * (std.math.pi / 180.0)),
        .ComptimeFloat => return @floatCast(d * (std.math.pi / 180.0)),
        .Int => {
            const rv: f32 = @floatFromInt(d);
            return rv * (std.math.pi / 180.0);
        },
        .ComptimeInt => {
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
    if (ti != .Vector) @compileError("input must be a vector");
    if (ti.Vector.len < 2) @compileError("input must be at least 2 dimensions");
    const child_type = @typeInfo(T).Vector.child;
    if (@typeInfo(child_type) == .Float or @typeInfo(child_type) == .ComptimeFloat) {
        const x: f32 = @floatCast(v[0]);
        const y: f32 = @floatCast(v[1]);
        const angle: f32 = std.math.atan2(y, x);
        const r: f32 = @sqrt(x * x + y * y);
        return .{ r, angle };
    }
    if (@typeInfo(child_type) == .It or @typeInfo(child_type) == .ComptimeInt) {
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
    if (ti != .Vector) @compileError("return type must be a vector");
    if (ti.Vector.len < 2) @compileError("return type must be at least 2 dimensions");
    const child_type = @typeInfo(T).Vector.child;
    if (@typeInfo(child_type) == .Float or @typeInfo(child_type) == .ComptimeFloat) {
        const r: f32 = coords[0];
        const angle: f32 = coords[1];
        const x: f32 = r * @cos(angle);
        const y: f32 = r * @sin(angle);
        var res: T = std.mem.zeroes(T);
        res[0] = x;
        res[1] = y;
        return res;
    }
    if (@typeInfo(child_type) == .It or @typeInfo(child_type) == .ComptimeInt) {
        const r: f32 = coords[0];
        const angle: f32 = coords[1];
        const x: f32 = r * @cos(angle);
        const y: f32 = r * @sin(angle);
        var res: T = undefined;
        @memset(&res, 0);
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

const std = @import("std");
const vector = @import("vector.zig");
const float = @import("float.zig");
