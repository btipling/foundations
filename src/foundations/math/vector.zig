pub const vec4 = @Vector(4, f32);

pub fn negate(v: anytype) @TypeOf(v) {
    const T = @TypeOf(v);
    switch (@typeInfo(T)) {
        .Vector => return v * @as(T, @splat(-1)),
        else => {},
    }
    @compileError("input must be a vector");
}

test negate {
    const a: vec4 = .{ 1, 2, 3, 0 };
    const ae: vec4 = .{ -1, -2, -3, 0 };
    try std.testing.expectEqual(ae, negate(a));
}

const std = @import("std");
