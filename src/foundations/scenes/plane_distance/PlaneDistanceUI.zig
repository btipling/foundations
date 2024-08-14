distance: usize = 0,
rotation_angle: f32 = 0,
rotation_axis: [3]f32 = .{ 0, 0, 1 },

const PlaneDistanceUI = @This();

pub fn draw(self: *PlaneDistanceUI) void {
    var buf: [250]u8 = undefined;
    const txt = std.fmt.bufPrintZ(&buf, "Distance to plane: {d}", .{
        self.distance,
    }) catch @panic("bufsize too small");
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Distance to Plane", null, 0);
    c.igText(@ptrCast(txt));

    if (c.igTreeNode_Str("plane normal")) {
        _ = c.igSliderFloat("angle", &self.rotation_angle, 0.01, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_None);
        c.igText("axis of rotation");
        _ = c.igSliderFloat("x", &self.rotation_axis[0], -1, 1, "%.3f", c.ImGuiSliderFlags_None);
        _ = c.igSliderFloat("y", &self.rotation_axis[1], -1, 1, "%.3f", c.ImGuiSliderFlags_None);
        _ = c.igSliderFloat("z", &self.rotation_axis[2], -1, 1, "%.3f", c.ImGuiSliderFlags_None);
        c.igTreePop();
    }
    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
const math = @import("../../math/math.zig");
