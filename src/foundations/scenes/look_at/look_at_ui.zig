camera: usize = 0,
grid_y_scale: math.vector.vec3 = .{ 5000, 0, 1 },
grid_y_translate: math.vector.vec3 = .{ -125, -2500, -235 },
grid_z_scale: math.vector.vec3 = .{ 5000, 0, 1 },
grid_z_translate: math.vector.vec3 = .{ -1303, 1888, -4281 },
grid_z_rot: math.vector.vec3 = .{ 1.922, 0, 1.320 },
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
    if (c.igTreeNode_Str("y scale")) {
        if (c.igSliderFloat(
            "x",
            &self.grid_y_scale[0],
            0,
            5000,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "y",
            &self.grid_y_scale[1],
            0,
            5000,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "z",
            &self.grid_y_scale[2],
            0.001,
            1,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        c.igTreePop();
    }
    if (c.igTreeNode_Str("y translate")) {
        if (c.igSliderFloat(
            "x",
            &self.grid_y_translate[0],
            -525,
            525,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "y",
            &self.grid_y_translate[1],
            -2500,
            2500,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "z",
            &self.grid_y_translate[2],
            -5000,
            1000,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        c.igTreePop();
    }
    if (c.igTreeNode_Str("z scale")) {
        if (c.igSliderFloat(
            "x",
            &self.grid_z_scale[0],
            0,
            5000,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "y",
            &self.grid_z_scale[1],
            0,
            5000,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "z",
            &self.grid_z_scale[2],
            0.001,
            1,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        c.igTreePop();
    }
    if (c.igTreeNode_Str("z translate")) {
        if (c.igSliderFloat(
            "x",
            &self.grid_z_translate[0],
            -5000,
            5000,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "y",
            &self.grid_z_translate[1],
            -5000,
            5000,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "z",
            &self.grid_z_translate[2],
            -5000,
            5000,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        c.igTreePop();
    }
    if (c.igTreeNode_Str("z rotate")) {
        if (c.igSliderFloat(
            "x",
            &self.grid_z_rot[0],
            0,
            std.math.pi * 2,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "y",
            &self.grid_z_rot[1],
            0,
            std.math.pi * 2,
            "%.3f",
            c.ImGuiSliderFlags_None,
        )) self.grid_updated = true;
        if (c.igSliderFloat(
            "z",
            &self.grid_z_rot[2],
            0,
            std.math.pi * 2,
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
