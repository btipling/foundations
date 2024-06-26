scale: f32 = 0.25,
x_rot: f32 = 0,
y_rot: f32 = 0,
z_rot: f32 = 0,
perspective: c_int = 0,

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
    c.igText("animated cubes");
    _ = c.igSliderFloat("scale", &self.scale, 0.01, 1, "%.3f", c.ImGuiSliderFlags_Logarithmic);
    _ = c.igSliderFloat("x rot", &self.x_rot, 0.01, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_Logarithmic);
    _ = c.igSliderFloat("y rot", &self.y_rot, 0.01, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_Logarithmic);
    _ = c.igSliderFloat("z rot", &self.z_rot, 0.01, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_Logarithmic);
    _ = c.igRadioButton_IntPtr("orthographic", &self.perspective, 0);
    c.igSameLine(0, 0);
    _ = c.igRadioButton_IntPtr("pinhole", &self.perspective, 1);
    c.igEnd();
}

const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cInclude("cimgui.h");
});

const std = @import("std");
const math = @import("../../math/math.zig");
const ui = @import("../../ui/ui.zig");
