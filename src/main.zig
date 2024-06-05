const c = @cImport({
    @cInclude("glad/gl.h");
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    std.debug.print("Starting up!\n", .{});
    try glfw.init();
    defer glfw.deinit();

    const width: c_int = 1920;
    const height: c_int = 1080;

    const win = try glfw.createWindow(width, height);
    defer glfw.destroyWindow(win);

    _ = c.gladLoadGL(c.glfwGetProcAddress);

    imgui.createContext(win);

    while (!glfw.shouldClose(win)) {
        glfw.pollEvents();
        c.glViewport(0, 0, @intCast(width), @intCast(height));
        gl.clear();
        imgui.frame();
        glfw.swapBuffers(win);
    }

    std.debug.print("Exiting!\n", .{});
}

test "test stub" {
    try std.testing.expect(true);
}

const std = @import("std");
const gl = @import("gl.zig");
const glfw = @import("glfw.zig");
const imgui = @import("imgui.zig");
