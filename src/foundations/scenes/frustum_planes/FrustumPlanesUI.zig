active_camera: usize = 0,

const FrustumPlanesUI = @This();

pub fn draw(self: *FrustumPlanesUI) void {
    var buf: [250]u8 = undefined;
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Frustum Plane Extraction", null, 0);

    {
        const txt = std.fmt.bufPrintZ(&buf, "Active camera {d:.3}", .{
            self.active_camera,
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }

    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
const math = @import("../../math/math.zig");
