pub fn draw() void {
    const btn_dims = ui.helpers().buttonSize();
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Navigation", null, 0);
    if (c.igCollapsingHeader_TreeNodeFlags("Shapes", 0)) {
        c.igText("Simple shapes drawn with OpenGL");
        if (c.igButton("Point", btn_dims)) {
            ui.state().demo_current = .point;
        }
        if (c.igButton("Rotating Point", btn_dims)) {
            ui.state().demo_current = .point_rotating;
        }
        if (c.igButton("Triangle", btn_dims)) {
            ui.state().demo_current = .triangle;
        }
        if (c.igButton("Animated Triangle", btn_dims)) {
            ui.state().demo_current = .triangle_animated;
        }
    }
    c.igEnd();
}

const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cInclude("cimgui.h");
});

const std = @import("std");
const ui = @import("ui.zig");
