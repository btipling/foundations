light_1: lightSetting = .{
    .position = .{ 1.784, -10.812, 0.057 },
    .attenuation = .{ 1, 1, 0 },
},
light_2: lightSetting = .{
    .position = .{ 1.776, -10.882, 0.323 },
    .attenuation = .{ 1, 1, 0 },
},
object_1: objectSetting = .{
    .position = .{ 1.225, -13.713, -0.083 },
    .model = 2,
    .polygon_factor = 150,
    .polygon_unit = 100,
},
object_2: objectSetting = .{
    .position = .{ 1.253, -9.667, -0.729 },
    .material = 4,
    .model = 1,
    .polygon_factor = 150,
    .polygon_unit = 100,
},
current_lights: usize = 0,
global_ambient: [4]f32 = .{ 0.7, 0.7, 0.7, 1 },

pub const lightSetting = struct {
    position: [3]f32 = .{ 0, 0, 0 },
    attenuation: [3]f32 = .{ 0, 0, 0 },
    color: [3]f32 = .{ 1, 1, 1 },
    updated: bool = false,
    data_updated: bool = false,
};

pub const objectSetting = struct {
    position: [3]f32 = .{ 0, 0, 0 },
    rotation: [3]f32 = .{ 0, 0, 0 },
    material: usize = 0,
    model: usize = 0,
    updated: bool = false,
    transform_updated: bool = false,
    polygon_factor: f32 = 0,
    polygon_unit: f32 = 0,
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
            c.igText("position");
            c.igPushItemWidth(-1);
            if (c.igSliderFloat("##l1tx", &self.light_1.position[0], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.data_updated = true;
            if (c.igSliderFloat("##l1ty", &self.light_1.position[1], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.data_updated = true;
            if (c.igSliderFloat("##l1tz", &self.light_1.position[2], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.data_updated = true;
        }
        {
            c.igText("attenuation");
            c.igPushItemWidth(-1);
            c.igText("constant");
            if (c.igSliderFloat("##l1ax", &self.light_1.attenuation[0], 1, 10, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.data_updated = true;
            c.igText("linear");
            if (c.igSliderFloat("##l1ay", &self.light_1.attenuation[1], 0, 1, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.data_updated = true;
            c.igText("quadratic");
            if (c.igSliderFloat("##l1az", &self.light_1.attenuation[2], 0, 1, "%.3f", c.ImGuiSliderFlags_None)) self.light_1.data_updated = true;
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
            if (c.igSliderFloat("##l2tx", &self.light_2.position[0], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_2.data_updated = true;
            if (c.igSliderFloat("##l2ty", &self.light_2.position[1], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_2.data_updated = true;
            if (c.igSliderFloat("##l2tz", &self.light_2.position[2], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_2.data_updated = true;
        }
        {
            c.igText("attenuation");
            c.igPushItemWidth(-1);
            c.igText("constant");
            if (c.igSliderFloat("##l2ax", &self.light_2.attenuation[0], 1, 10, "%.3f", c.ImGuiSliderFlags_None)) self.light_2.data_updated = true;
            c.igText("linear");
            if (c.igSliderFloat("##l2ay", &self.light_2.attenuation[1], 0, 1, "%.3f", c.ImGuiSliderFlags_None)) self.light_2.data_updated = true;
            c.igText("quadratic");
            if (c.igSliderFloat("##l2az", &self.light_2.attenuation[2], 0, 1, "%.3f", c.ImGuiSliderFlags_None)) self.light_2.data_updated = true;
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
        c.igText("polygon offset factor");
        if (c.igSliderFloat("##o1pof", &self.object_1.polygon_factor, -10000.0, 10000.0, "%.3f", c.ImGuiSliderFlags_None)) self.object_1.transform_updated = true;
        c.igText("polygon offset unit");
        if (c.igSliderFloat("##o1pou", &self.object_1.polygon_unit, -10000.0, 10000.0, "%.3f", c.ImGuiSliderFlags_None)) self.object_1.transform_updated = true;
    }

    {
        c.igNewLine();
        c.igText("Object 2");
    }
    {
        const preview = materials_list[self.object_2.material];
        const flags = c.ImGuiComboFlags_PopupAlignLeft | c.ImGuiComboFlags_HeightLargest;
        const selectable_size = ui.get_helpers().selectableSize();
        if (c.igBeginCombo("##Materials2", preview, flags)) {
            for (0..materials_list.len) |i| {
                const is_selected: bool = i == self.object_2.material;
                if (c.igSelectable_Bool(materials_list[i], is_selected, 0, selectable_size)) {
                    self.object_2.material = i;
                    self.object_2.updated = true;
                }
                if (is_selected) {
                    c.igSetItemDefaultFocus();
                }
            }
            c.igEndCombo();
        }
    }
    {
        const preview = model_list[self.object_2.model];
        const flags = c.ImGuiComboFlags_PopupAlignLeft | c.ImGuiComboFlags_HeightLargest;
        const selectable_size = ui.get_helpers().selectableSize();
        if (c.igBeginCombo("##Objects2", preview, flags)) {
            for (0..model_list.len) |i| {
                const is_selected: bool = i == self.object_2.model;
                if (c.igSelectable_Bool(model_list[i], is_selected, 0, selectable_size)) {
                    self.object_2.model = i;
                    self.object_2.updated = true;
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
        if (c.igSliderFloat("##o2tx", &self.object_2.position[0], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.object_2.transform_updated = true;
        if (c.igSliderFloat("##o2ty", &self.object_2.position[1], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.object_2.transform_updated = true;
        if (c.igSliderFloat("##o2tz", &self.object_2.position[2], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.object_2.transform_updated = true;
        c.igText("rotation");
        if (c.igSliderFloat("##o2rx", &self.object_2.rotation[0], 0, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_None)) self.object_2.transform_updated = true;
        if (c.igSliderFloat("##o2ry", &self.object_2.rotation[1], 0, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_None)) self.object_2.transform_updated = true;
        if (c.igSliderFloat("##o2rz", &self.object_2.rotation[2], 0, std.math.pi * 2, "%.3f", c.ImGuiSliderFlags_None)) self.object_2.transform_updated = true;
        c.igText("polygon offset factor");
        if (c.igSliderFloat("##o2pof", &self.object_2.polygon_factor, -10000.0, 10000.0, "%.3f", c.ImGuiSliderFlags_None)) self.object_2.transform_updated = true;
        c.igText("polygon offset unit");
        if (c.igSliderFloat("##o2pou", &self.object_2.polygon_unit, -10000.0, 10000.0, "%.3f", c.ImGuiSliderFlags_None)) self.object_2.transform_updated = true;
    }
    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
const ui = @import("../../../../ui/ui.zig");
