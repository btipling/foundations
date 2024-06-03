pub fn main() !void {
    std.debug.print("Starting up!\n", .{});
    try glfw.init();
    defer glfw.deinit();
    std.debug.print("Exiting!\n", .{});
}

test "test stub" {
    try std.testing.expect(true);
}

const std = @import("std");
const glfw = @import("glfw.zig");
