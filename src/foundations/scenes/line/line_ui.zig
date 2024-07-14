mode: interpolation = interpolation.linear,

const line_ui = @This();

pub const interpolation = enum(u8) {
    linear,
    hermite,
};

pub fn init(allocator: std.mem.Allocator) *line_ui {
    const lu = allocator.create(line_ui) catch @panic("OOM");
    lu.* = .{};
    return lu;
}

pub fn deinit(self: *line_ui, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *line_ui) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Line", null, 0);
    c.igText("Line");
    var mode: c_int = @intFromEnum(self.mode);
    _ = c.igRadioButton_IntPtr("linear", &mode, 0);
    c.igSameLine(0, 0);
    _ = c.igRadioButton_IntPtr("hermite", &mode, 1);
    self.mode = @enumFromInt(mode);
    c.igText("Click point to select it.");
    c.igText("In hermite mode:");
    c.igText("Ctrl+click to create tangents");
    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
