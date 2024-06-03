const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub fn init() void {
    if (c.glfwInit() == 0) {
        std.debug.print("could not init glfw", .{});
        return;
    }
    std.debug.print("successfully inited glfw", .{});
}

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 11);
}

const std = @import("std");
