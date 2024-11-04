light_direction: [4]f32 = .{ 4.0, 2.0, -3.75, 0 },
light_updated: bool = true,

const SimulatingWaterUI = @This();

pub fn draw(self: *SimulatingWaterUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Light position", null, 0);

    _ = c.igText("translation");
    if (c.igSliderFloat("##trx", &self.light_direction[0], -20.0, 20.0, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
    if (c.igSliderFloat("##try", &self.light_direction[1], -20.0, 20.0, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
    if (c.igSliderFloat("##trz", &self.light_direction[2], -20.0, 20.0, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;

    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
