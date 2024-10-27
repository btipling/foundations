pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    // ft3d - the foundation 3D texture generator
    const generator_exe = b.addExecutable(.{
        .name = "ft3d",
        .root_source_file = b.path("src/ft3d.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(generator_exe);

    const ft3d_cmd = b.addRunArtifact(generator_exe);

    ft3d_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        ft3d_cmd.addArgs(args);
    }

    const ft3d_step = b.step("ft3d", "Build a 3D texture");
    ft3d_step.dependOn(&ft3d_cmd.step);
}

const std = @import("std");
