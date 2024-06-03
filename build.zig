const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "foundations",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // GLFW stuff
    exe.addIncludePath(b.path("libs/glfw/include"));
    exe.linkLibC();
    switch (target.result.os.tag) {
        .windows => {
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("shell32");
            exe.addCSourceFiles(.{
                .files = &.{
                    "libs/glfw/src/platform.c",
                    "libs/glfw/src/monitor.c",
                    "libs/glfw/src/init.c",
                    "libs/glfw/src/vulkan.c",
                    "libs/glfw/src/input.c",
                    "libs/glfw/src/context.c",
                    "libs/glfw/src/window.c",
                    "libs/glfw/src/osmesa_context.c",
                    "libs/glfw/src/egl_context.c",
                    "libs/glfw/src/null_init.c",
                    "libs/glfw/src/null_monitor.c",
                    "libs/glfw/src/null_window.c",
                    "libs/glfw/src/null_joystick.c",
                    "libs/glfw/src/wgl_context.c",
                    "libs/glfw/src/win32_thread.c",
                    "libs/glfw/src/win32_init.c",
                    "libs/glfw/src/win32_monitor.c",
                    "libs/glfw/src/win32_time.c",
                    "libs/glfw/src/win32_joystick.c",
                    "libs/glfw/src/win32_window.c",
                    "libs/glfw/src/win32_module.c",
                },
                .flags = &.{"-D_GLFW_WIN32"},
            });
        },
        else => @panic("this projectonly builds on windows"),
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
