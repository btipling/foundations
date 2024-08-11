camera: usize = 0,
grid_y_scale: math.vector.vec3 = .{ 5000, 1, 1 },
grid_y_translate: math.vector.vec3 = .{ -67, -2500, -5000 },
grid_z_scale: math.vector.vec3 = .{ 5000, 1, 1 },
grid_z_translate: math.vector.vec3 = .{ -68.5, -1071, -2578 },
grid_z_rot: math.vector.vec3 = .{ std.math.pi / 2.0, 0, std.math.pi / 2.0 },
cube_translate: math.vector.vec3 = .{ 0.0, 10.5, 0.0 },
cube_rot: math.vector.vec3 = .{ std.math.pi / 1.5, 0.25, std.math.pi / 2.0 },

const pr_ui = @This();

pub fn draw(self: *pr_ui) void {
    var buf: [250]u8 = undefined;
    const txt = std.fmt.bufPrintZ(&buf, "current camera: {d}", .{
        self.camera,
    }) catch @panic("bufsize too small");
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("lookAt", null, 0);
    c.igText(@ptrCast(txt));
    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
const math = @import("../../math/math.zig");
