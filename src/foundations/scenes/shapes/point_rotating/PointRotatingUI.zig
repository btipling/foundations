r: f32,
rotation_time: f32,

const pr_ui = @This();

pub fn draw(self: *pr_ui) void {
    var buf: [250]u8 = undefined;
    const txt = std.fmt.bufPrintZ(&buf, "speed: {d} seconds radius: {d}", .{
        self.r,
        self.rotation_time,
    }) catch @panic("bufsize too small");
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Rotating Point", null, 0);
    c.igText(@ptrCast(txt));
    _ = c.igSliderFloat("radius", &self.r, 0.1, 1.0, "%.4f", c.ImGuiSliderFlags_Logarithmic);
    _ = c.igSliderFloat("speed", &self.rotation_time, 0.1, 5.0, "%.4f", c.ImGuiSliderFlags_Logarithmic);
    c.igEnd();
}

const std = @import("std");
const c = @import("../../../c.zig").c;
