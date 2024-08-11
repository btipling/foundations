distance: usize = 0,

const PlaneDistanceUI = @This();

pub fn draw(self: *PlaneDistanceUI) void {
    var buf: [250]u8 = undefined;
    const txt = std.fmt.bufPrintZ(&buf, "Distance to plane: {d}", .{
        self.distance,
    }) catch @panic("bufsize too small");
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Distance to Plane", null, 0);
    c.igText(@ptrCast(txt));
    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
const math = @import("../../math/math.zig");
