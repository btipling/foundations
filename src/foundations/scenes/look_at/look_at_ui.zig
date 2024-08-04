camera: usize = 0,
grid_scale: math.vector.vec3 = .{ 115, 500, 0.5 },
grid_translate: math.vector.vec3 = .{ -21, 18, -55 },
grid_updated: bool = false,

const pr_ui = @This();

pub fn draw(self: *pr_ui) void {
    var buf: [250]u8 = undefined;
    const txt = std.fmt.bufPrintZ(&buf, "current camera: {d}", .{
        self.camera,
    }) catch @panic("bufsize too small");
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("lookAt", null, 0);
    c.igText(@ptrCast(txt));
    if (c.igTreeNode_Str("scale")) {
        if (c.igSliderFloat(
            "x",
            &self.grid_scale[0],
            0.5,
            2500,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "y",
            &self.grid_scale[1],
            0.5,
            2500,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "z",
            &self.grid_scale[2],
            0.5,
            500,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        c.igTreePop();
    }
    if (c.igTreeNode_Str("translate")) {
        if (c.igSliderFloat(
            "x",
            &self.grid_translate[0],
            -525,
            525,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "y",
            &self.grid_translate[1],
            0,
            525,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "z",
            &self.grid_translate[2],
            -525,
            525,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        c.igTreePop();
    }
    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
const math = @import("../../math/math.zig");
