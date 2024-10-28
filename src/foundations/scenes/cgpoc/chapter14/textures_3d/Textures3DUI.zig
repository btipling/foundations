light_rotation: [3]f32 = .{ 0.424, 4.773, 4.348 },
light_position: [3]f32 = .{ 1.086, 3.163, -0.199 },
light_updated: bool = true,

const Textures3DUI = @This();

pub fn draw(self: *Textures3DUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Light rotation", null, 0);

    if (c.igSliderFloat("##prx", &self.light_rotation[0], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
    if (c.igSliderFloat("##pry", &self.light_rotation[1], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
    if (c.igSliderFloat("##prz", &self.light_rotation[2], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;

    if (c.igSliderFloat("##trx", &self.light_position[0], -10.0, 10.0, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
    if (c.igSliderFloat("##try", &self.light_position[1], -10.0, 10.0, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
    if (c.igSliderFloat("##trz", &self.light_position[2], -10.0, 10.0, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;

    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
