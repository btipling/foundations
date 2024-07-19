scale: f32 = 0.25,
x_rot: f32 = 4.060,
y_rot: f32 = 2.525,
z_rot: f32 = 2.760,
x_translate: f32 = 0,
y_translate: f32 = 0,
z_translate: f32 = 0,
use_lh_x_up: c_int = 1,
animate: bool = true,
use_slerp: c_int = 1,

const ca_ui = @This();

pub fn init() ca_ui {
    return .{};
}

pub fn draw(self: *ca_ui) void {
    const btn_dims = ui.helpers().buttonSize();
    _ = btn_dims;
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Animated cubes", null, 0);
    _ = c.igSliderFloat("scale", &self.scale, 0.01, 1, "%.3f", c.ImGuiSliderFlags_None);
    if (c.igTreeNode_Str("rotation")) {
        _ = c.igSliderFloat("x", &self.x_rot, 0.01, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_None);
        _ = c.igSliderFloat("y", &self.y_rot, 0.01, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_None);
        _ = c.igSliderFloat("z", &self.z_rot, 0.01, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_None);
        c.igTreePop();
    }
    if (c.igTreeNode_Str("translate")) {
        _ = c.igSliderFloat("x", &self.x_translate, -1, 1, "%.3f", c.ImGuiSliderFlags_None);
        _ = c.igSliderFloat("y", &self.y_translate, -1, 1, "%.3f", c.ImGuiSliderFlags_None);
        _ = c.igSliderFloat("z", &self.z_translate, -1, 1, "%.3f", c.ImGuiSliderFlags_None);
        c.igTreePop();
    }
    _ = c.igCheckbox("animate", &self.animate);
    _ = c.igRadioButton_IntPtr("slerp", &self.use_slerp, 1);
    c.igSameLine(0, 0);
    _ = c.igRadioButton_IntPtr("lerp", &self.use_slerp, 0);
    _ = c.igRadioButton_IntPtr("left handed x up", &self.use_lh_x_up, 1);
    c.igSameLine(0, 0);
    _ = c.igRadioButton_IntPtr("NDC", &self.use_lh_x_up, 0);
    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
const math = @import("../../math/math.zig");
const ui = @import("../../ui/ui.zig");
