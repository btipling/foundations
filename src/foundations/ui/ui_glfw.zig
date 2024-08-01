pub const window = c.GLFWwindow;

pub const GLFWError = error{
    Fatal,
    NotFound,
};

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("GLFW Error: {d} {s}\n", .{ err, description });
}

pub fn init(cfg: *config) !void {
    if (c.glfwInit() == c.GL_FALSE) {
        std.debug.print("could not init glfw\n", .{});
        return GLFWError.Fatal;
    }
    _ = c.glfwSetErrorCallback(errorCallback);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
    c.glfwWindowHint(c.GLFW_MAXIMIZED, @intFromBool(cfg.maximized));
    c.glfwWindowHint(c.GLFW_DECORATED, @intFromBool(cfg.decorated));
    c.glfwWindowHint(c.GLFW_RESIZABLE, 0);

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

pub fn createWindow(cfg: *config) !*window {
    monitorInfo(cfg);
    const win: *c.GLFWwindow = c.glfwCreateWindow(
        @intCast(cfg.width),
        @intCast(cfg.height),
        "Foundations!",
        null,
        null,
    ) orelse return GLFWError.Fatal;
    c.glfwMakeContextCurrent(win);
    c.glfwSwapInterval(1);
    _ = c.gladLoadGL(c.glfwGetProcAddress);
    return win;
}

fn monitorInfo(cfg: *config) void {
    const m = c.glfwGetPrimaryMonitor() orelse @panic("no primary monitor");
    const vm = c.glfwGetVideoMode(m);
    var changed = false;
    if (cfg.width == 0) {
        cfg.width = @intCast(vm.*.width);
        changed = true;
    }
    if (cfg.height == 0) {
        cfg.height = @intCast(vm.*.height);
        changed = true;
    }
    if (changed) cfg.save();
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

const std = @import("std");
const c = @import("../c.zig").c;
const config = @import("../config/config.zig");
