x: f32 = 0.0,
z: f32 = 0.0,
distance_vector: math.vector.vec3 = .{ 0, 0, 0 },
point_vector: ?vData = null,
origin_point: vData = .{
    .position = .{ 0.5, 0.0, 0.0 },
    .color = yellow,
},
vs: [2]vData = .{
    .{
        .position = .{ 0.5, 0.0, 0.0 },
        .color = yellow,
    },
    .{
        .position = .{ -0.5, 0.0, 0.5 },
        .color = yellow,
    },
},
over_vertex: ?mouseVertexCapture = null,

pub const mouseVertexCapture = struct {
    dragging: bool = false,
    vertex: usize = 0,
};

pub const vData = struct {
    position: math.vector.vec3,
    color: math.vector.vec4,
};

pub const green = .{ 0.41, 1.0, 0.71, 1 };
pub const yellow = .{ 1.0, 0.95, 0.41, 1.0 };
pub const pink = .{ 1.0, 0.41, 0.71, 1 };

const pr_ui = @This();

pub fn draw(self: *pr_ui) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Distance to line", null, 0);

    {
        var buf: [250]u8 = undefined;
        const txt = std.fmt.bufPrintZ(&buf, "last pos: ({d:.3}, 0.0, {d:.3})", .{
            self.x,
            self.z,
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }

    {
        var buf: [250]u8 = undefined;
        const txt = std.fmt.bufPrintZ(&buf, "distance vector: ({d:.3}, {d:.3}, {d:.3})", .{
            self.distance_vector[0],
            self.distance_vector[1],
            self.distance_vector[2],
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }

    if (self.point_vector) |pv| {
        var buf: [250]u8 = undefined;
        const txt = std.fmt.bufPrintZ(&buf, "point: ({d:.3}, {d:.3}, {d:.3})", .{
            pv.position[0],
            pv.position[1],
            pv.position[2],
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }

    c.igEnd();
}

const std = @import("std");
const c = @import("../../c.zig").c;
const math = @import("../../math/math.zig");
