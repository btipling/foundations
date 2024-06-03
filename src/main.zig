pub fn main() !void {
    std.debug.print("Starting up!\n", .{});
    try glfw.init();
    defer glfw.deinit();

    const win = try glfw.createWindow();
    defer glfw.destroyWindow(win);

    while (!glfw.shouldClose(win)) {
        glfw.pollEvents();
    }

    std.debug.print("Exiting!\n", .{});
}

test "test stub" {
    try std.testing.expect(true);
}

const std = @import("std");
const glfw = @import("glfw.zig");
