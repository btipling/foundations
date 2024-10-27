distance: usize = 0,
plane_rotation: [3]f32 = .{
    std.math.pi,
    std.math.pi,
    std.math.pi,
},
plane_translate: [3]f32 = .{ 0, -15, -20 },
plane_updated: bool = true,

const CipplingPlaneUI = @This();

pub fn draw(self: *CipplingPlaneUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Clipping Plane", null, 0);

    c.igText("plane rotation");
    c.igPushItemWidth(-1);
    if (c.igSliderFloat("##prx", &self.plane_rotation[0], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;
    if (c.igSliderFloat("##pry", &self.plane_rotation[1], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;
    if (c.igSliderFloat("##prz", &self.plane_rotation[2], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;

    c.igText("plane translate");
    c.igPushItemWidth(-1);
    if (c.igSliderFloat("##ptx", &self.plane_translate[0], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;
    if (c.igSliderFloat("##pty", &self.plane_translate[1], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;
    if (c.igSliderFloat("##ptz", &self.plane_translate[2], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;

    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
