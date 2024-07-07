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

    std.debug.print("successfully inited glfw and gl\n", .{});
}

pub fn deinit() void {
    c.glfwTerminate();
}

pub fn contentScale(win: *window) f32 {
    var x: f32 = 0;
    var y: f32 = 1;
    c.glfwGetWindowContentScale(win, @ptrCast(&x), @ptrCast(&y));
    return @max(x, y) * 0.9;
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
    c.glfwSwapInterval(1);
    _ = c.gladLoadGL(c.glfwGetProcAddress);
    registerGLFWCallbacks(win);
    return win;
}

fn cursorPosCallback(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    std.debug.print("cursorPosCallback - x: {d} y: {d}\n", .{ x, y });
}

fn mouseButtonCallback(_: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    std.debug.print("mouseButtonCallback - button: {d} action: {d} mods: {d}\n", .{ button, action, mods });
}

fn registerGLFWCallbacks(win: *c.GLFWwindow) void {
    _ = c.glfwSetCursorPosCallback(win, cursorPosCallback);
    _ = c.glfwSetMouseButtonCallback(win, mouseButtonCallback);
}

pub fn getTime() f64 {
    return @floatCast(c.glfwGetTime());
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

const c = @import("../c.zig").c;
const std = @import("std");
