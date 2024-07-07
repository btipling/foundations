mouse_x: ?f64 = null,
mouse_y: ?f64 = null,
mouse_button: ?c_int = null,
mouse_action: ?c_int = null,
mouse_mods: ?c_int = null,

const Input = @This();

var input: ?*Input = null;

pub fn init(allocator: std.mem.Allocator, win: *c.GLFWwindow) *Input {
    if (input != null) return input.?;
    input = allocator.create(Input) catch @panic("OOM");
    registerGLFWCallbacks(win);
    return input.?;
}

pub fn deinit(self: *Input, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
    input = null;
}

fn cursorPosCallback(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    std.debug.print("cursorPosCallback - x: {d} y: {d}\n", .{ x, y });
    const inp = input orelse return;
    inp.mouse_x = x;
    inp.mouse_y = y;
}

fn mouseButtonCallback(_: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    std.debug.print("mouseButtonCallback - button: {d} action: {d} mods: {d}\n", .{ button, action, mods });
    const inp = input orelse return;
    inp.mouse_button = button;
    inp.mouse_action = action;
    inp.mouse_mods = mods;
}

pub fn get() *Input {
    return input orelse @panic("accessed invalid input");
}

fn registerGLFWCallbacks(win: *c.GLFWwindow) void {
    _ = c.glfwSetCursorPosCallback(win, cursorPosCallback);
    _ = c.glfwSetMouseButtonCallback(win, mouseButtonCallback);
}

fn endFrame(self: *Input) void {
    self.* = .{};
}

const std = @import("std");
const c = @import("../c.zig").c;
