pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    // fssc - the foundation simple shader compiler
    const compiler_exe = b.addExecutable(.{
        .name = "fssc",
        .root_source_file = b.path("src/compiler.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(compiler_exe);

    const fssc_cmd = b.addRunArtifact(compiler_exe);

    fssc_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        fssc_cmd.addArgs(args);
    }

    const fssc_step = b.step("fssc", "Compile a shder");
    fssc_step.dependOn(&fssc_cmd.step);
}

const std = @import("std");
