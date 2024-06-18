vectors: [100]math.vector.vec2 = undefined,
num_vectors: usize = 0,
next_vec_data: [2]f32 = .{ 0, 0 },

pub const max_vectors: usize = 100;

const vma_ui = @This();

pub fn draw(self: *vma_ui) void {
    const btn_dims = ui.helpers().buttonSize();
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Math vector arithmetic", null, 0);
    _ = c.igInputFloat2("##add", &self.next_vec_data, "%.3f", c.ImGuiInputTextFlags_None);
    if (c.igButton("Add vector", btn_dims)) {
        self.addVector();
    }
    if (c.igButton("Clear vectors", btn_dims)) {
        self.clearVectors();
    }
    if (c.igButton("Print vectors", btn_dims)) {
        self.printVectors();
    }
    c.igEnd();
}

fn addVector(self: *vma_ui) void {
    if (self.num_vectors + 1 == max_vectors) return;
    self.vectors[self.num_vectors] = self.next_vec_data;
    self.num_vectors += 1;
    self.clearInput();
}

fn printVectors(self: *vma_ui) void {
    var i: usize = 0;
    std.debug.print("vectors:\n", .{});
    while (i < self.num_vectors) : (i += 1) {
        std.debug.print("\t({d}, {d})\n", .{
            self.vectors[i][0],
            self.vectors[i][1],
        });
    }
}

fn clearInput(self: *vma_ui) void {
    self.next_vec_data = .{ 0, 0 };
}

fn clearVectors(self: *vma_ui) void {
    self.clearInput();
    self.num_vectors = 0;
}

const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cInclude("cimgui.h");
});

const std = @import("std");
const math = @import("../../math/math.zig");
const ui = @import("../../ui/ui.zig");
