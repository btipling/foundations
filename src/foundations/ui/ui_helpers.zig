scale: f32,

const helpers = @This();

pub fn buttonSize(self: helpers) c.ImVec2 {
    return c.ImVec2_ImVec2_Float(200 * self.scale, 25 * self.scale).*;
}

const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cInclude("cimgui.h");
});

const glfw = @import("ui_glfw.zig");
