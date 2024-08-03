mouse_x: ?f32 = null,
mouse_y: ?f32 = null,
coord_x: ?f32 = null,
coord_z: ?f32 = null,
mouse_button: ?c_int = null,
mouse_action: ?c_int = null,
mouse_mods: ?c_int = null,
win_width: f32,
win_height: f32,
clear_input: bool = false,

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

fn cursorPosCallback(_: ?*c.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    const io = c.igGetIO().*;
    if (io.WantCaptureMouse) return;
    const inp = input orelse return;
    const _x: f32 = @floatCast(x);
    const _y: f32 = @floatCast(y);
    inp.mouse_x = ((_x / inp.win_width) - 0.5) * 2;
    inp.mouse_y = ((_y / inp.win_height) - 0.5) * -2;
    inp.coord_x = inp.mouse_y;
    inp.coord_z = inp.mouse_x;
}

fn mouseButtonCallback(_: ?*c.GLFWwindow, button: c_int, action: c_int, mods: c_int) callconv(.C) void {
    const io = c.igGetIO().*;
    if (io.WantCaptureMouse) return;
    const inp = input orelse return;
    inp.mouse_button = button;
    inp.mouse_action = action;
    inp.mouse_mods = mods;
    inp.clear_input = inp.mouse_action == c.GLFW_RELEASE;
}

pub fn get() ?*Input {
    return input;
}

pub fn getReadOnly() ?*const Input {
    return input;
}

fn registerGLFWCallbacks(win: *c.GLFWwindow) void {
    _ = c.glfwSetCursorPosCallback(win, cursorPosCallback);
    _ = c.glfwSetMouseButtonCallback(win, mouseButtonCallback);
}

pub fn endFrame(self: *Input) void {
    if (!self.clear_input) return;
    self.* = .{
        .win_width = self.win_width,
        .win_height = self.win_height,
        .mouse_x = self.mouse_x,
        .mouse_y = self.mouse_y,
        .coord_x = self.coord_x,
        .coord_z = self.coord_z,
    };
}

const std = @import("std");
const c = @import("../c.zig").c;
