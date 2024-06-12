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

    const cflags = &.{"-D_GLFW_WIN32"};

    // GLFW stuff
    exe.addIncludePath(b.path("libs/glad/include"));
    exe.addIncludePath(b.path("libs/glfw/include"));
    exe.addIncludePath(b.path("libs/cimgui"));
    exe.addIncludePath(b.path("libs/cimgui/generator/output"));
    exe.addIncludePath(b.path("libs/cimgui/imgui"));
    exe.addIncludePath(b.path("libs/cimgui/imgui/backends"));
    exe.linkLibC();
    exe.linkLibCpp();
    switch (target.result.os.tag) {
        .windows => {
            exe.linkSystemLibrary("gdi32");
            exe.linkSystemLibrary("user32");
            exe.linkSystemLibrary("shell32");
            exe.addCSourceFiles(.{
                .files = &.{
                    "libs/glad/src/gl.c",
                },
                .flags = cflags,
            });
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
                .flags = cflags,
            });
            exe.addCSourceFiles(.{
                .files = &.{
                    "libs/cimgui/cimgui.cpp",
                    "libs/cimgui/imgui/imgui.cpp",
                    "libs/cimgui/imgui/imgui_demo.cpp",
                    "libs/cimgui/imgui/imgui_draw.cpp",
                    "libs/cimgui/imgui/imgui_tables.cpp",
                    "libs/cimgui/imgui/imgui_widgets.cpp",
                },
                .flags = cflags,
            });
            exe.addCSourceFiles(.{
                .files = &.{
                    "libs/cimgui/imgui/backends/imgui_impl_glfw.cpp",
                    "libs/cimgui/imgui/backends/imgui_impl_opengl3.cpp",
                },
                .flags = &(cflags.* ++ .{"-DIMGUI_IMPL_API=extern \"C\" __declspec(dllexport)"}),
            });
        },
        else => @panic("this project only builds on windows"),
    }

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const test_step = b.step("test", "Run tests");
    const tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
    });
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);
}
