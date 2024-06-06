pub fn main() !void {
    std.debug.print("Starting up!\n", .{});
    try ui.glfw.init();
    defer ui.glfw.deinit();

    const width: c_int = 1920;
    const height: c_int = 1080;

    const win = try ui.glfw.createWindow(width, height);
    defer ui.glfw.destroyWindow(win);

    _ = c.gladLoadGL(c.glfwGetProcAddress);

    ui.init(win);
    defer ui.deinit();

    while (!ui.glfw.shouldClose(win)) {
        ui.glfw.pollEvents();
        c.glViewport(0, 0, @intCast(width), @intCast(height));
        rhi.clear();
        ui.beginFrame();
        ui.hellWorld();
        ui.endFrame();
        ui.glfw.swapBuffers(win);
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
const rhi = @import("rhi/rhi.zig");
const ui = @import("ui/ui.zig");
