pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, _: std.builtin.OptimizeMode) void {
    const test_step = b.step("test", "Run tests");
    const tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
    });
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);
}

const std = @import("std");
