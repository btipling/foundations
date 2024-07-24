x: f32 = 0.0,
z: f32 = 0.0,
vs: [3]vData = .{
    .{
        .position = .{ 0.5, 0.0, 0.0 },
        .color = yellow,
    },
    .{
        .position = .{ -0.5, 0.0, 0.5 },
        .color = yellow,
    },
    .{
        .position = .{ -0.5, 0.0, -0.5 },
        .color = yellow,
    },
},
over_circle: bool = false,
within_circle: bool = false,
over_vertex: ?usize = null,

pub const vData = struct {
    position: math.vector.vec3,
    color: math.vector.vec4,
};

pub const green = .{ 0.41, 1.0, 0.71, 1 };
pub const yellow = .{ 1.0, 0.95, 0.41, 1.0 };
pub const pink = .{ 1.0, 0.41, 0.71, 1 };

const pr_ui = @This();

pub fn draw(self: *pr_ui) void {
    var buf: [250]u8 = undefined;
    const txt = std.fmt.bufPrintZ(&buf, "last pos: ({d}, 0.0, {d})", .{
        self.x,
        self.z,
    }) catch @panic("bufsize too small");
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Unit circle", null, 0);
    const text_color: *c.ImVec4 = if (self.over_circle)
        c.ImVec4_ImVec4_Float(0.41, 1.0, 0.71, 1)
    else if (self.within_circle) c.ImVec4_ImVec4_Float(1.0, 0.95, 0.41, 1.0) else c.ImVec4_ImVec4_Float(1.0, 0.41, 0.71, 1);
    c.igTextColored(text_color.*, @ptrCast(txt));
    c.igText("[x(t) = cos(2 * pi * t), y(t) = sin(2 * pi * t)]");
    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
const math = @import("../../math/math.zig");
