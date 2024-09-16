pub const default_epsilon = 0.000001;

// It is not correct to compare to floats for equality directly, this compares them within a small range
pub fn equal(v: anytype, k: anytype, epsilon: anytype) bool {
    if (@typeInfo(@TypeOf(v)) != .float and @typeInfo(@TypeOf(v)) != .comptime_float) @compileError("first input must be a float");
    if (@typeInfo(@TypeOf(k)) != .float and @typeInfo(@TypeOf(k)) != .comptime_float) @compileError("second input must be a float");
    if (@typeInfo(@TypeOf(epsilon)) != .float and @typeInfo(@TypeOf(epsilon)) != .comptime_float) @compileError("epsilon must be a float");
    return @abs(v - k) <= epsilon * @max(@abs(v), @abs(k), 1);
}

test equal {
    try std.testing.expect(equal(1.001, 1.002, 0.01));
}

pub fn equal_e(v: anytype, k: anytype) bool {
    return equal(v, k, default_epsilon);
}

const std = @import("std");
