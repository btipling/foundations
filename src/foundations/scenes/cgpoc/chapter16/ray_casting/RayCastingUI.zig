updated: bool = false,
sphere_pos: [3]f32 = .{ 1, 0, -3 },

const ComputeShaderUI = @This();

pub fn draw(self: *ComputeShaderUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Raycasting", null, 0);
    c.igPushItemWidth(-1);

    if (c.igSliderFloat("##spx", &self.sphere_pos[0], -5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
    if (c.igSliderFloat("##spy", &self.sphere_pos[1], -5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
    if (c.igSliderFloat("##spz", &self.sphere_pos[2], -5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;

    _ = c.igText("Ray casting?");
    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
