pub const vec4 = @Vector(4, f32);

pub fn negate(v: anytype) @TypeOf(v) {
    return mul(v, -1);
}

pub fn mul(v: anytype, m: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    const K = @TypeOf(m);
    switch (@typeInfo(T)) {
        .Vector => |VT| switch (@typeInfo(K)) {
            .Float, .Int, .ComptimeFloat, .ComptimeInt => return v * @as(T, @splat(m)),
            .Vector => |VM| if (VT.len != VM.len) @compileError("mismatched vector length") else return v * m,
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
    try std.testing.expectEqual(ae, mul(a, 2));
    const b: vec4 = .{ 1, 2, 3, 0 };
    const be: vec4 = .{ 10, -20, 9, 0 };
    try std.testing.expectEqual(be, mul(b, @as(vec4, .{ 10, -10, 3, 100 })));
}

const std = @import("std");
