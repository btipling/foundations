pub fn build(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    // ft3d - the foundation 3D texture generator
    const generator_exe = b.addExecutable(.{
        .name = "ft3d",
        .root_source_file = b.path("src/ft3d.zig"),
        .target = target,
        .optimize = optimize,
    });

    const cflags = &.{"-D_GLFW_WIN32"};

    generator_exe.addIncludePath(b.path("libs/stb/include"));
    generator_exe.linkLibC();
    generator_exe.linkLibCpp();
    switch (target.result.os.tag) {
        .windows => {
            generator_exe.linkSystemLibrary("gdi32");
            generator_exe.linkSystemLibrary("user32");
            generator_exe.linkSystemLibrary("shell32");
            generator_exe.linkSystemLibrary("WS2_32");
            generator_exe.addCSourceFiles(.{
                .files = &.{
                    "libs/stb/src/stb_perlin.c",
                },
                .flags = cflags,
            });
        },
        else => @panic("this project only builds on windows"),
    }

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
