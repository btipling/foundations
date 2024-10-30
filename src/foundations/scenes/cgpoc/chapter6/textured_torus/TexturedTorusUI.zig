disintegrate: bool = false,
disintegration: f32 = 0,

const TexturedTorusUI = @This();

pub fn draw(self: *TexturedTorusUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("##TexturedTorusUI", null, 0);

    const btn_dims = ui.get_helpers().buttonSize();
    if (self.disintegrate) {
        if (c.igButton("Reset", btn_dims)) {
            self.disintegrate = false;
            self.disintegration = 0;
        }
    } else {
        if (c.igButton("Disintegrate", btn_dims)) {
            self.disintegrate = true;
        }
    }

    c.igEnd();
}

const std = @import("std");
const ui = @import("../../../../ui/ui.zig");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
