pub fn main() !void {
    std.debug.print("Starting up!\n", .{});
    try glfw.init();
    defer glfw.deinit();

    const width: c_int = 1920;
    const height: c_int = 1080;

    const win = try glfw.createWindow(width, height);
    defer glfw.destroyWindow(win);

    _ = c.gladLoadGL(c.glfwGetProcAddress);

    ui.init(win);
    defer ui.deinit();

    while (!glfw.shouldClose(win)) {
        glfw.pollEvents();
        c.glViewport(0, 0, @intCast(width), @intCast(height));
        rhi.clear();
        ui.beginFrame();
        ui.hellWorld();
        ui.endFrame();
        glfw.swapBuffers(win);
    }

    std.debug.print("Exiting!\n", .{});
}

test "test stub" {
    try std.testing.expect(true);
}

const c = @cImport({
    @cInclude("glad/gl.h");
    @cInclude("GLFW/glfw3.h");
});

const std = @import("std");
const rhi = @import("rhi.zig");
const glfw = @import("glfw.zig");
const ui = @import("ui.zig");
