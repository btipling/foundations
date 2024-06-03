const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const GLFWError = error{
    Fatal,
};

pub fn init() !void {
    if (c.glfwInit() == 0) {
        std.debug.print("could not init glfw", .{});
        return GLFWError.Fatal;
    }
    std.debug.print("successfully inited glfw", .{});
}

pub fn deinit() void {
    c.glfwTerminate();
}

const std = @import("std");
