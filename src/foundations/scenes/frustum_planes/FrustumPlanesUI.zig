active_view_camera: c_int = 0,
active_input_camera: c_int = 0,
use_clip_plane_extraction: c_int = 0,

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
        const txt = std.fmt.bufPrintZ(&buf, "Active view camera {d:.3}", .{
            self.active_view_camera + 1,
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }
    {
        const txt = std.fmt.bufPrintZ(&buf, "Active input camera {d:.3}", .{
            self.active_input_camera + 1,
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }

    c.igText("Active view camera");
    _ = c.igRadioButton_IntPtr("view camera 1", &self.active_view_camera, 0);
    c.igSameLine(0, 1);
    _ = c.igRadioButton_IntPtr("view camera 2", &self.active_view_camera, 1);
    c.igText("Active input camera");
    _ = c.igRadioButton_IntPtr("input camera 1", &self.active_input_camera, 0);
    c.igSameLine(0, 1);
    _ = c.igRadioButton_IntPtr("input camera 2", &self.active_input_camera, 1);
    c.igText("Use clip plane extraction");
    _ = c.igRadioButton_IntPtr("use camera plane extraction", &self.use_clip_plane_extraction, 0);
    c.igSameLine(0, 1);
    _ = c.igRadioButton_IntPtr("use clip plane extraction", &self.use_clip_plane_extraction, 1);

    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
const math = @import("../../math/math.zig");
