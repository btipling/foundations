mouse_x: ?f32 = null,
mouse_z: ?f32 = null,
mouse_button: ?c_int = null,
mouse_action: ?c_int = null,
mouse_mods: ?c_int = null,
win_width: f32,
win_height: f32,

const Input = @This();

var input: ?*Input = null;

pub fn init(allocator: std.mem.Allocator, win: *c.GLFWwindow) *Input {
    if (input != null) return input.?;
    const inp = allocator.create(Input) catch @panic("OOM");
    var width: c_int = 0;
    var height: c_int = 0;
    c.glfwGetFramebufferSize(win, &width, &height);
    inp.* = .{
        .win_width = @floatFromInt(width),
        .win_height = @floatFromInt(height),
    };
    registerGLFWCallbacks(win);
    input = inp;
    return inp;
}

pub fn deinit(self: *Input, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
    input = null;
}

fn cursorPosCallback(_: ?*c.GLFWwindow, z: f64, x: f64) callconv(.C) void {
    const inp = input orelse return;
    const _x: f32 = @floatCast(x);
    const _z: f32 = @floatCast(z);
    inp.mouse_x = _x / inp.win_height;
    inp.mouse_z = _z / inp.win_width;
}

fn mouseButtonCallback(_: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    const inp = input orelse return;
    inp.mouse_button = button;
    inp.mouse_action = action;
    inp.mouse_mods = mods;
}

pub fn get() ?*Input {
    return input;
}

fn registerGLFWCallbacks(win: *c.GLFWwindow) void {
    _ = c.glfwSetCursorPosCallback(win, cursorPosCallback);
    _ = c.glfwSetMouseButtonCallback(win, mouseButtonCallback);
}

pub fn endFrame(self: *Input) void {
    self.* = .{
        .win_width = self.win_width,
        .win_height = self.win_height,
    };
}

const std = @import("std");
const c = @import("../c.zig").c;
