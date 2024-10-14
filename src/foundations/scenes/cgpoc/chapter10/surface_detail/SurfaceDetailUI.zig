light_position: math.vector.vec3 = .{ 1.784, -10.812, 0.057 },
light_updated: bool = true,

const ShadowsUI = @This();

pub fn draw(self: *ShadowsUI) void {
    self.drawLight();
}

fn drawLight(self: *ShadowsUI) void {
    var buf: [250]u8 = undefined;
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Light", null, 0);
    {
        c.igNewLine();
        c.igText("Light");
        {
            const txt = std.fmt.bufPrintZ(&buf, "Position: ({d:.3}, {d:.3}, {d:.3}", .{
                self.light_position[0],
                self.light_position[1],
                self.light_position[2],
            }) catch @panic("bufsize too small");
            c.igText(@ptrCast(txt));
        }
        {
            c.igText("position");
            c.igPushItemWidth(-1);
            if (c.igSliderFloat("##l1tx", &self.light_position[0], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
            if (c.igSliderFloat("##l1ty", &self.light_position[1], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
            if (c.igSliderFloat("##l1tz", &self.light_position[2], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
        }
    }
    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
const ui = @import("../../../../ui/ui.zig");
