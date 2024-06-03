const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const GLFWError = error{
    Fatal,
};

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("GLFW Error: {d} {s}\n", .{ err, description });
}

pub fn init() !void {
    if (c.glfwInit() == c.GL_FALSE) {
        std.debug.print("could not init glfw\n", .{});
        return GLFWError.Fatal;
    }
    _ = c.glfwSetErrorCallback(errorCallback);
    std.debug.print("successfully inited glfw\n", .{});
}

pub fn deinit() void {
    c.glfwTerminate();
}

pub fn createWindow() !*c.GLFWwindow {
    const win: *c.GLFWwindow = c.glfwCreateWindow(
        640,
        480,
        "Foundations!",
        null,
        null,
    ) orelse return GLFWError.Fatal;
    c.glfwMakeContextCurrent(win);
    return win;
}

pub fn pollEvents() void {
    c.glfwPollEvents();
}

pub fn shouldClose(win: *c.GLFWwindow) bool {
    return c.glfwWindowShouldClose(win) == c.GL_TRUE;
}

pub fn destroyWindow(win: *c.GLFWwindow) void {
    c.glfwDestroyWindow(win);
}

const std = @import("std");
