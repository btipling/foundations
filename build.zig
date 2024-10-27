pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    foundation.build(b, target, optimize);
    fssc.build(b, target, optimize);
    tests.build(b, target, optimize);
}

const std = @import("std");
const foundation = @import("build_foundation.zig");
const fssc = @import("build_fssc.zig");
const tests = @import("build_tests.zig");
