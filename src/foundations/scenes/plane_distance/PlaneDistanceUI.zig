distance: usize = 0,
rotation: [3]f32 = .{
    std.math.pi,
    std.math.pi,
    std.math.pi,
},
translate: [3]f32 = .{ -100, -100, -100 },
updated: bool = true,

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

    if (c.igTreeNode_Str("plane normal rotation")) {
        if (c.igSliderFloat("x", &self.rotation[0], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
        if (c.igSliderFloat("y", &self.rotation[1], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
        if (c.igSliderFloat("z", &self.rotation[2], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
        c.igTreePop();
    }
    if (c.igTreeNode_Str("plane normal translate")) {
        if (c.igSliderFloat("x", &self.translate[0], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
        if (c.igSliderFloat("y", &self.translate[1], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
        if (c.igSliderFloat("z", &self.translate[2], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.updated = true;
        c.igTreePop();
    }
    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
const math = @import("../../math/math.zig");
