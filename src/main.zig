pub fn main() !void {
    std.debug.print("Starting up!\n", .{});
    try glfw.init();
    defer glfw.deinit();

    const width: c_int = 1920;
    const height: c_int = 1080;

    const win = try glfw.createWindow(width, height);
    defer glfw.destroyWindow(win);

    try gl.loadAll();

    imgui.createContext();

    while (!glfw.shouldClose(win)) {
        glfw.pollEvents();
        gl.glViewport(0, 0, @intCast(width), @intCast(height));
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
        gl.glClearColor(0.5, 0, 1, 1);
        glfw.swapBuffers(win);
    }

    std.debug.print("Exiting!\n", .{});
}

test "test stub" {
    try std.testing.expect(true);
}

const std = @import("std");
const glfw = @import("glfw.zig");
const gl = @import("gl.zig");
const imgui = @import("imgui.zig");
