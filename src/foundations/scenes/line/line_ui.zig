mode: interpolation = interpolation.linear,

const pr_ui = @This();

pub const interpolation = enum(u8) {
    linear,
    hermite,
};

pub fn draw(self: *pr_ui) void {
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
    if (self.mode == .hermite) {
        c.igText("Ctrl+click points to create tangents");
    }
    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
