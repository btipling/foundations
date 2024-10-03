object_1: objectSetting = .{
    .position = .{ 0.73, -9.914, 0 },
},
object_2: objectSetting = .{
    .position = .{ 1.253, -9.667, -0.729 },
},

pub const objectSetting = struct {
    position: [3]f32 = .{ 0, 0, 0 },
    rotation: [3]f32 = .{ 0, 0, 0 },
    model: usize = 0,
    updated: bool = false,
    transform_updated: bool = false,
};

const ShadowsUI = @This();

pub fn draw(self: *ShadowsUI) void {
    self.drawObjects();
}

fn drawObjects(self: *ShadowsUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    const window_flags = 0;
    _ = c.igBegin("Objects", null, window_flags);

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

    {
        c.igNewLine();
        c.igText("Object 2");
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
    }
    c.igEnd();
}

const std = @import("std");
const c = @import("../../../c.zig").c;
const math = @import("../../../math/math.zig");
const ui = @import("../../../ui/ui.zig");
