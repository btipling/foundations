light_1: lightSetting = .{
    .position = .{ 0, -11.121, 2.366 },
},
light_2: lightSetting = .{
    .position = .{ 0.796, -12.688, -1.372 },
},
object_1: objectSetting = .{
    .position = .{ 1, -10, 0 },
},
current_lights: usize = 0,
global_ambient: [4]f32 = .{ 0.7, 0.7, 0.7, 1 },

pub const lightSetting = struct {
    position: [3]f32 = .{ 0, 0, 0 },
    color: [3]f32 = .{ 1, 1, 1 },
    updated: bool = false,
    position_updated: bool = false,
};

pub const objectSetting = struct {
    position: [3]f32 = .{ 0, 0, 0 },
    rotation: [3]f32 = .{ 0, 0, 0 },
    material: usize = 0,
    model: usize = 0,
    updated: bool = false,
    transform_updated: bool = false,
};

const ShadowsUI = @This();

pub fn draw(self: *ShadowsUI) void {
    self.drawLights();
    self.drawMaterials();
}

fn drawLights(self: *ShadowsUI) void {
    var buf: [250]u8 = undefined;
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Light", null, 0);
    {
        const items = [_][*]const u8{
            "Blinn Phong",
            "Phong",
            "Gouraud",
        };
        c.igText("current light: ");
        c.igSameLine(0, 0);
        c.igText(items[self.current_lights]);
        const data: [*c]const [*c]const u8 = items[0..].ptr;
        c.igPushItemWidth(-1);
        if (c.igListBox_Str_arr("##lightslist", @ptrCast(&self.current_lights), data, items.len, -1)) {
            self.object_1.updated = true;
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
            self.object_1.updated = true;
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
            self.object_1.updated = true;
        }
    }
    c.igEnd();
}

fn drawMaterials(self: *ShadowsUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    const window_flags = 0;
    _ = c.igBegin("Objects", null, window_flags);

    const materials_list = [_][*]const u8{
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
    const model_list = [_][*]const u8{
        "Torus",
        "Parallelepiped",
        "Sphere",
        "Cone",
        "Cylinder",
        "Pyramid",
        "Shuttle",
        "Dolphin Lowpoly",
        "Dolphin highpoly",
    };

    {
        c.igNewLine();
        c.igText("Object 1");
    }
    {
        const preview = materials_list[self.object_1.material];
        const flags = c.ImGuiComboFlags_PopupAlignLeft | c.ImGuiComboFlags_HeightLargest;
        const selectable_size = ui.get_helpers().selectableSize();
        if (c.igBeginCombo("##Materials1", preview, flags)) {
            for (0..materials_list.len) |i| {
                const is_selected: bool = i == self.object_1.material;
                if (c.igSelectable_Bool(materials_list[i], is_selected, 0, selectable_size)) {
                    self.object_1.material = i;
                    self.object_1.updated = true;
                }
                if (is_selected) {
                    c.igSetItemDefaultFocus();
                }
            }
            c.igEndCombo();
        }
    }
    {
        const preview = model_list[self.object_1.model];
        const flags = c.ImGuiComboFlags_PopupAlignLeft | c.ImGuiComboFlags_HeightLargest;
        const selectable_size = ui.get_helpers().selectableSize();
        if (c.igBeginCombo("##Objects1", preview, flags)) {
            for (0..model_list.len) |i| {
                const is_selected: bool = i == self.object_1.model;
                if (c.igSelectable_Bool(model_list[i], is_selected, 0, selectable_size)) {
                    self.object_1.model = i;
                    self.object_1.updated = true;
                }
                if (is_selected) {
                    c.igSetItemDefaultFocus();
                }
            }
            c.igEndCombo();
        }
    }
    {
        c.igPushItemWidth(-1);
        c.igText("position");
        if (c.igSliderFloat("##o1tx", &self.object_1.position[0], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.object_1.transform_updated = true;
        if (c.igSliderFloat("##o1ty", &self.object_1.position[1], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.object_1.transform_updated = true;
        if (c.igSliderFloat("##o1tz", &self.object_1.position[2], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.object_1.transform_updated = true;
        c.igText("rotation");
        if (c.igSliderFloat("##o1rx", &self.object_1.rotation[0], 0, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_None)) self.object_1.transform_updated = true;
        if (c.igSliderFloat("##o1ry", &self.object_1.rotation[1], 0, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_None)) self.object_1.transform_updated = true;
        if (c.igSliderFloat("##o1rz", &self.object_1.rotation[2], 0, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_None)) self.object_1.transform_updated = true;
    }
    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
const ui = @import("../../../../ui/ui.zig");
