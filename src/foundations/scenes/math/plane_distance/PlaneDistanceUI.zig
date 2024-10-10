distance: usize = 0,
plane_rotation: [3]f32 = .{
    std.math.pi,
    std.math.pi,
    std.math.pi,
},
plane_translate: [3]f32 = .{ 0, -15, -20 },
plane_updated: bool = true,
cube_rotation: [3]f32 = .{
    std.math.pi,
    std.math.pi + std.math.pi * 0.25,
    std.math.pi - std.math.pi * 0.25,
},
cube_translate: [3]f32 = .{ 3, -2, 2 },
cube_updated: bool = true,
closest_point_to_origin: [4]f32 = .{ 0, 0, 0, 0 },
origin_distance: f32 = 0,
cube_distance: f32 = 0,
cube_point: [4]f32 = .{ 0, 0, 0, 0 },

const PlaneDistanceUI = @This();

pub fn draw(self: *PlaneDistanceUI) void {
    var buf: [250]u8 = undefined;
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Distance to Plane", null, 0);
    {
        const txt = std.fmt.bufPrintZ(&buf, "Closest point to origin: ({d:.3}, {d:.3}, {d:.3}, {d:.3})", .{
            self.closest_point_to_origin[0],
            self.closest_point_to_origin[1],
            self.closest_point_to_origin[2],
            self.closest_point_to_origin[3],
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }
    {
        const txt = std.fmt.bufPrintZ(&buf, "Plane distance to origin: {d:.3}", .{
            self.origin_distance,
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }
    {
        const txt = std.fmt.bufPrintZ(&buf, "Closest point to cube: ({d:.3}, {d:.3}, {d:.3}, {d:.3})", .{
            self.cube_point[0],
            self.cube_point[1],
            self.cube_point[2],
            self.cube_point[3],
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }
    {
        const txt = std.fmt.bufPrintZ(&buf, "Plane distance to cube: {d:.3}", .{
            self.cube_distance,
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }

    c.igText("plane rotation");
    c.igPushItemWidth(-1);
    if (c.igSliderFloat("##prx", &self.plane_rotation[0], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;
    if (c.igSliderFloat("##pry", &self.plane_rotation[1], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;
    if (c.igSliderFloat("##prz", &self.plane_rotation[2], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;

    c.igText("plane translate");
    c.igPushItemWidth(-1);
    if (c.igSliderFloat("##ptx", &self.plane_translate[0], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;
    if (c.igSliderFloat("##pty", &self.plane_translate[1], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;
    if (c.igSliderFloat("##ptz", &self.plane_translate[2], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.plane_updated = true;

    c.igText("cube rotation");
    c.igPushItemWidth(-1);
    if (c.igSliderFloat("##crx", &self.cube_rotation[0], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.cube_updated = true;
    if (c.igSliderFloat("##cry", &self.cube_rotation[1], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.cube_updated = true;
    if (c.igSliderFloat("##crz", &self.cube_rotation[2], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.cube_updated = true;

    c.igText("cube translate");
    c.igPushItemWidth(-1);
    if (c.igSliderFloat("##ctx", &self.cube_translate[0], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.cube_updated = true;
    if (c.igSliderFloat("##cty", &self.cube_translate[1], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.cube_updated = true;
    if (c.igSliderFloat("##ctz", &self.cube_translate[2], -100, 100, "%.3f", c.ImGuiSliderFlags_None)) self.cube_updated = true;

    c.igEnd();
}

const std = @import("std");
const c = @import("../../../c.zig").c;
const math = @import("../../../math/math.zig");
