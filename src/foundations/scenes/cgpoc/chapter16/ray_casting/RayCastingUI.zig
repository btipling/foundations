updated: bool = false,
sphere_radius: f32 = 2.5,
sphere_pos: [3]f32 = .{ 1, 0, -3 },
box_dim: f32 = 0.5,
box_pos: [3]f32 = .{ 0.5, 0.0, 0.0 },

const ComputeShaderUI = @This();

pub fn draw(self: *ComputeShaderUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Raycasting", null, 0);
    c.igPushItemWidth(-1);

    _ = c.igText("Sphere radius");
    if (c.igSliderFloat("##sr", &self.sphere_radius, 0.5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
    _ = c.igText("Sphere position");
    if (c.igSliderFloat("##spx", &self.sphere_pos[0], -5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
    if (c.igSliderFloat("##spy", &self.sphere_pos[1], -5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
    if (c.igSliderFloat("##spz", &self.sphere_pos[2], -5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;

    _ = c.igText("Box dimension");
    if (c.igSliderFloat("##bd", &self.box_dim, 0.5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
    _ = c.igText("Box position");
    if (c.igSliderFloat("##bpx", &self.box_pos[0], -5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
    if (c.igSliderFloat("##bpy", &self.box_pos[1], -5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
    if (c.igSliderFloat("##bpz", &self.box_pos[2], -5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;

    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
