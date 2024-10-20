light_1: lightSetting = .{
    .position = .{ 0, 0, 0 },
    .attenuation_constant = 1.0,
},
global_ambient: [4]f32 = .{ 0.01, 0.01, 0.01, 1 },
wire_frame: bool = false,

pub const lightSetting = struct {
    position: [3]f32 = .{ 0, 0, 0 },
    color: [3]f32 = .{ 1, 1, 1 },
    updated: bool = false,
    position_updated: bool = false,
    attenuation_constant: f32 = 1,
    attenuation_linear: f32 = 0,
    attenuation_quadratic: f32 = 0,
};

const TerrainTessellatorUI = @This();

pub fn draw(self: *TerrainTessellatorUI) void {
    var buf: [250]u8 = undefined;
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Terrain", null, 0);

    {
        c.igNewLine();
        c.igText("Light");
        {
            const txt = std.fmt.bufPrintZ(&buf, "Position: ({d:.3}, {d:.3}, {d:.3}", .{
                self.light_1.position[0],
                self.light_1.position[1],
                self.light_1.position[2],
            }) catch @panic("bufsize too small");
            c.igText(@ptrCast(txt));
        }
        {
            c.igPushItemWidth(-1);
            if (c.igSliderFloat("##l1x", &self.light_1.position[0], -50, 50, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.position_updated = true;
            if (c.igSliderFloat("##l1y", &self.light_1.position[1], -50, 50, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.position_updated = true;
            if (c.igSliderFloat("##l1z", &self.light_1.position[2], -50, 50, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.position_updated = true;
        }
        c.igText("Attenuation");
        {
            c.igPushItemWidth(-1);
            c.igText("Constant");
            if (c.igSliderFloat("##a1x", &self.light_1.attenuation_constant, 1, 5, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.updated = true;
            c.igText("Linear");
            if (c.igSliderFloat("##a1y", &self.light_1.attenuation_linear, 0, 1, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.updated = true;
            c.igText("Quadratic");
            if (c.igSliderFloat("##a1z", &self.light_1.attenuation_quadratic, 0, 1, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.updated = true;
        }
        const flags = c.ImGuiColorEditFlags_NoInputs | c.ImGuiColorEditFlags_NoLabel;
        if (c.igColorEdit3("##Color1", @ptrCast(&self.light_1.color), flags)) {
            self.light_1.updated = true;
        }
        if (c.igCheckbox("wireframe", &self.wire_frame)) {}
    }

    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
