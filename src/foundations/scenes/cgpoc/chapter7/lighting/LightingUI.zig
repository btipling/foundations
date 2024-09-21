light_position: [3]f32 = .{ 0, -12, -0.0 },
light_updated: bool = false,
torus_updated: bool = false,
current_material: usize = 0,

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
        const txt = std.fmt.bufPrintZ(&buf, "Light position: ({d:.3}, {d:.3}, {d:.3}", .{
            self.light_position[0],
            self.light_position[1],
            self.light_position[2],
        }) catch @panic("bufsize too small");
        c.igText(@ptrCast(txt));
    }
    if (c.igSliderFloat("x", &self.light_position[0], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
    if (c.igSliderFloat("y", &self.light_position[1], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;
    if (c.igSliderFloat("z", &self.light_position[2], -25, 25, "%.3f", c.ImGuiSliderFlags_None)) self.light_updated = true;

    //  const char* items[] = { "Apple", "Banana", "Cherry", "Kiwi", "Mango", "Orange", "Pineapple", "Strawberry", "Watermelon" };
    //     static int item_current = 1;
    //     ImGui::ListBox("listbox", &item_current, items, IM_ARRAYSIZE(items), 4);
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
    c.igText("Materials");
    c.igText("current material: ");
    c.igSameLine(0, 0);
    c.igText(items[self.current_material]);
    const data: [*c]const [*c]const u8 = items[0..].ptr;
    if (c.igListBox_Str_arr("##materialslist", @ptrCast(&self.current_material), data, items.len, -1)) {
        self.torus_updated = true;
    }

    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
