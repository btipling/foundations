wire_frame: bool = false,

const LodTessellatorUI = @This();

pub fn draw(self: *LodTessellatorUI) void {
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Terrain LOD", null, 0);

    {
        if (c.igCheckbox("wireframe", &self.wire_frame)) {}
    }

    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
