active_texture: c_int = 0,

const TexturedPyramidUI = @This();

pub fn draw(self: *TexturedPyramidUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Textured Pyramid", null, 0);
    c.igText("Active Texture");
    _ = c.igRadioButton_IntPtr("Brick", &self.active_texture, 0);
    _ = c.igRadioButton_IntPtr("Ice", &self.active_texture, 1);
    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
