const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub const window = c.GLFWwindow;

pub const GLFWError = error{
    Fatal,
    NotFound,
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
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
    std.debug.print("successfully inited glfw\n", .{});
}

pub fn deinit() void {
    c.glfwTerminate();
}

pub fn createWindow(width: c_int, height: c_int) !*window {
    const win: *c.GLFWwindow = c.glfwCreateWindow(
        width,
        height,
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

pub fn shouldClose(win: *window) bool {
    return c.glfwWindowShouldClose(win) == c.GL_TRUE;
}

pub fn destroyWindow(win: *window) void {
    c.glfwDestroyWindow(win);
}

pub fn swapBuffers(win: *window) void {
    c.glfwSwapBuffers(win);
}

pub fn getProcAddress(comptime T: type, name: []const u8) !T {
    if (c.glfwGetProcAddress(@ptrCast(name))) |gl_func| {
        return @as(T, @ptrFromInt(@intFromPtr(gl_func)));
    }
    return GLFWError.NotFound;
}

const std = @import("std");
