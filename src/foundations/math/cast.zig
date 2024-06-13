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

const std = @import("std");
