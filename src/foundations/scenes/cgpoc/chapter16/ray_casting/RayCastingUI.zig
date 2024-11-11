data: [num_images]ImgData = undefined,
updating: usize = 0,

pub const num_images: usize = 9;

pub const ImgData = struct {
    sphere_radius: f32 = 2.5,
    sphere_pos: [3]f32 = .{ 1, 0, -3 },
    sphere_color: [3]f32 = .{ 0, 1, 0 },
    box_dim: f32 = 1.5,
    box_pos: [3]f32 = .{ -0.175, -0.018, 0.0 },
    box_color: [3]f32 = .{ 1, 0, 0 },
    box_rot: [3]f32 = .{ 0.566, 1.650, 2.074 },
    light_pos: [4]f32 = .{ 3, 2, 4, 1 },
    camera_pos: [4]f32 = .{ 0, 0, 5, 1 },
    camera_dir: [4]f32 = .{ 0, 0, 0, 0 },
    updated: bool = true,
};

const ComputeShaderUI = @This();

pub fn draw(self: *ComputeShaderUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Raycasting", null, 0);
    c.igPushItemWidth(-1);

    const img_list = [num_images][*]const u8{
        "1",
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
    };

    {
        c.igNewLine();
        c.igText("Image updating");
    }
    {
        const preview = img_list[self.updating];
        const flags = c.ImGuiComboFlags_PopupAlignLeft | c.ImGuiComboFlags_HeightLargest;
        const selectable_size = ui.get_helpers().selectableSize();
        if (c.igBeginCombo("##images_list", preview, flags)) {
            for (0..img_list.len) |i| {
                const is_selected: bool = i == self.updating;
                if (c.igSelectable_Bool(img_list[i], is_selected, 0, selectable_size)) {
                    self.updating = i;
                }
                if (is_selected) {
                    c.igSetItemDefaultFocus();
                }
            }
            c.igEndCombo();
        }
    }

    _ = c.igText("Sphere radius");
    if (c.igSliderFloat("##sr", &self.data[self.updating].sphere_radius, 0.5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    _ = c.igText("Sphere position");
    if (c.igSliderFloat("##spx", &self.data[self.updating].sphere_pos[0], -10, 10, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##spy", &self.data[self.updating].sphere_pos[1], -10, 10, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##spz", &self.data[self.updating].sphere_pos[2], -10, 10, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;

    _ = c.igText("Sphere color");
    {
        const flags = c.ImGuiColorEditFlags_NoInputs | c.ImGuiColorEditFlags_NoLabel;
        if (c.igColorEdit3("##Spolor1", @ptrCast(&self.data[self.updating].sphere_color), flags)) {
            self.data[self.updating].updated = true;
        }
    }

    _ = c.igText("Box dimension");
    if (c.igSliderFloat("##bd", &self.data[self.updating].box_dim, 0.5, 5, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    _ = c.igText("Box position");
    if (c.igSliderFloat("##bpx", &self.data[self.updating].box_pos[0], -10, 10, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##bpy", &self.data[self.updating].box_pos[1], -10, 10, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##bpz", &self.data[self.updating].box_pos[2], -10, 10, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    _ = c.igText("Box rotation");
    if (c.igSliderFloat("##brx", &self.data[self.updating].box_rot[0], 0, std.math.pi, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##bry", &self.data[self.updating].box_rot[1], 0, std.math.pi, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##brz", &self.data[self.updating].box_rot[2], 0, std.math.pi, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;

    _ = c.igText("Box color");
    {
        const flags = c.ImGuiColorEditFlags_NoInputs | c.ImGuiColorEditFlags_NoLabel;
        if (c.igColorEdit3("##Bpolor1", @ptrCast(&self.data[self.updating].box_color), flags)) {
            self.data[self.updating].updated = true;
        }
    }

    _ = c.igText("Light position");
    if (c.igSliderFloat("##lpx", &self.data[self.updating].light_pos[0], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##lpy", &self.data[self.updating].light_pos[1], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##lpz", &self.data[self.updating].light_pos[2], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;

    _ = c.igText("Camera position");
    if (c.igSliderFloat("##cposx", &self.data[self.updating].camera_pos[0], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##cposy", &self.data[self.updating].camera_pos[1], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##cposz", &self.data[self.updating].camera_pos[2], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;

    _ = c.igText("Camera direction");
    if (c.igSliderFloat("##cdx", &self.data[self.updating].camera_dir[0], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##cdy", &self.data[self.updating].camera_dir[1], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;
    if (c.igSliderFloat("##cdz", &self.data[self.updating].camera_dir[2], 0, std.math.pi * 2.0, "%.3f", c.ImGuiSliderFlags_None)) self.data[self.updating].updated = true;

    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
const ui = @import("../../../../ui/ui.zig");
