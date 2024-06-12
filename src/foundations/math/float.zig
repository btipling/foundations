// It is not correct to compare to floats for equality directly, this compares them within a small range
pub fn equal(v: anytype, k: anytype, epsilon: anytype) bool {
    if (@typeInfo(@TypeOf(v)) != .Float and @typeInfo(@TypeOf(v)) != .ComptimeFloat) @compileError("first input must be a float");
    if (@typeInfo(@TypeOf(k)) != .Float and @typeInfo(@TypeOf(k)) != .ComptimeFloat) @compileError("second input must be a float");
    if (@typeInfo(@TypeOf(epsilon)) != .Float and @typeInfo(@TypeOf(epsilon)) != .ComptimeFloat) @compileError("epsilon must be a float");
    return @abs(v - k) <= epsilon * @max(@abs(v), @abs(k), 1);
}

test equal {
    try std.testing.expect(equal(1.001, 1.002, 0.01));
}

const std = @import("std");
