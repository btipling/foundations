pub fn main() !void {
    const res: i32 = glfw.add(1, 2);
    std.debug.print("add result: {d}\n", .{res});
    glfw.init();
}

test "test stub" {
    try std.testing.expect(true);
}

const std = @import("std");
const glfw = @import("glfw.zig");
