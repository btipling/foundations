scale: f32,

const helpers = @This();

pub fn selectableSize(self: helpers) c.ImVec2 {
    return c.ImVec2_ImVec2_Float(200 * self.scale, 20 * self.scale).*;
}

pub fn buttonSize(self: helpers) c.ImVec2 {
    return c.ImVec2_ImVec2_Float(100 * self.scale, 20 * self.scale).*;
}

const c = @import("../c.zig").c;
const glfw = @import("ui_glfw.zig");
