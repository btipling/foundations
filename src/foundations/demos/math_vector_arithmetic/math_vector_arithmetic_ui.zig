points: [100]math.vector.vec3 = undefined,
num_points: usize = 0,

const vma_ui = @This();

pub fn draw(_: *vma_ui) void {
    const btn_dims = ui.helpers().buttonSize();
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Math vector arithmetic", null, 0);
    if (c.igButton("Add vector", btn_dims)) {
        std.debug.print("adding a vector\n", .{});
    }
    c.igText("Math vector arithmetic");
    c.igEnd();
}

const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cInclude("cimgui.h");
});

const std = @import("std");
const math = @import("../../math/math.zig");
const ui = @import("../../ui/ui.zig");
