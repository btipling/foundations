light_1: lightSetting = .{
    .position = .{ 0, -12, 0.0 },
},
light_2: lightSetting = .{
    .position = .{ -0.624, -12.688, -1.372 },
},
torus_updated: bool = false,
current_material: usize = 0,
current_lighting: usize = 0,

pub const lightSetting = struct {
    position: [3]f32 = .{ 0, 0, 0 },
    color: [3]f32 = .{ 1, 1, 1 },
    updated: bool = false,
    position_updated: bool = false,
};

const LightingUI = @This();

pub fn draw(self: *LightingUI) void {
    var buf: [250]u8 = undefined;
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Lighting", null, 0);
    {
        const items = [_][*]const u8{
            "Blinn Phong",
            "Phong",
            "Gouraud",
        };
        c.igText("current lighting: ");
        c.igSameLine(0, 0);
        c.igText(items[self.current_lighting]);
        const data: [*c]const [*c]const u8 = items[0..].ptr;
        c.igPushItemWidth(-1);
        if (c.igListBox_Str_arr("##lightingslist", @ptrCast(&self.current_lighting), data, items.len, -1)) {
            self.torus_updated = true;
        }
    }
    {
        const items = [_][*]const u8{
            "Gold",
            "Jade",
            "Pearl",
            "Silver",
            "Copper",
            "Chrome",
            "Emerald",
            "Ruby",
            "Obsidian",
            "Brass",
        };
        c.igNewLine();
        c.igText("Materials");
        c.igText("current material: ");
        c.igSameLine(0, 0);
        c.igText(items[self.current_material]);
        const data: [*c]const [*c]const u8 = items[0..].ptr;
        c.igPushItemWidth(-1);
        if (c.igListBox_Str_arr("##materialslist", @ptrCast(&self.current_material), data, items.len, -1)) {
            self.torus_updated = true;
        }
    }
    {
        c.igNewLine();
        c.igText("Light 1");
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
            if (c.igSliderFloat("##l1x", &self.light_1.position[0], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.position_updated = true;
            if (c.igSliderFloat("##l1y", &self.light_1.position[1], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.position_updated = true;
            if (c.igSliderFloat("##l1z", &self.light_1.position[2], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.position_updated = true;
        }
        const flags = c.ImGuiColorEditFlags_NoInputs | c.ImGuiColorEditFlags_NoLabel;
        if (c.igColorEdit3("##Color1", @ptrCast(&self.light_1.color), flags)) {
            self.light_1.updated = true;
            self.torus_updated = true;
        }
    }
    {
        c.igNewLine();
        c.igText("Light 2");
        {
            const txt = std.fmt.bufPrintZ(&buf, "Position: ({d:.3}, {d:.3}, {d:.3}", .{
                self.light_2.position[0],
                self.light_2.position[1],
                self.light_2.position[2],
            }) catch @panic("bufsize too small");
            c.igText(@ptrCast(txt));
        }
        {
            c.igPushItemWidth(-1);
            if (c.igSliderFloat("##l2x", &self.light_2.position[0], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_2.position_updated = true;
            if (c.igSliderFloat("##l2y", &self.light_2.position[1], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_2.position_updated = true;
            if (c.igSliderFloat("##l2z", &self.light_2.position[2], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_2.position_updated = true;
        }
        const flags = c.ImGuiColorEditFlags_NoInputs | c.ImGuiColorEditFlags_NoLabel;
        if (c.igColorEdit3("##Color2", @ptrCast(&self.light_2.color), flags)) {
            self.light_2.updated = true;
            self.torus_updated = true;
        }
    }

    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
