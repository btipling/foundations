vectors: [100]data = undefined,
num_vectors: usize = 0,
points: [101]math.vector.vec3 = undefined,
point_selected: usize = 0,
num_points: usize = 0,
next_vec_data: [3]f32 = .{ 0, 0, 0 },

pub const max_vectors: usize = 100;

pub const data = struct {
    origin: math.vector.vec3,
    vector: math.vector.vec3,
};

const vma_ui = @This();

pub fn init() vma_ui {
    var ui_state: vma_ui = .{};
    ui_state.points[0] = .{ 0, 0, 0 };
    ui_state.point_selected = 0;
    ui_state.num_points += 1;
    return ui_state;
}

pub fn draw(self: *vma_ui) void {
    const btn_dims = ui.helpers().buttonSize();
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Math vector arithmetic", null, 0);
    _ = c.igInputFloat2("##add", &self.next_vec_data, "%.3f", c.ImGuiInputTextFlags_None);
    self.drawPoints();
    self.drawVectors();
    if (c.igButton("Clear data", btn_dims)) {
        self.clearData();
    }
    if (c.igButton("Print vectors", btn_dims)) {
        self.printVectors();
    }
    c.igEnd();
}

fn drawPoints(self: *vma_ui) void {
    const scale = ui.helpers().scale;
    const selectable_dims = c.ImVec2_ImVec2_Float(100 * scale, 20 * scale).*;
    const flags = c.ImGuiSelectableFlags_SpanAvailWidth | c.ImGuiSelectableFlags_AllowDoubleClick;
    if (c.igTreeNode_Str("points")) {
        var i: usize = 0;
        var buf: [250]u8 = undefined;
        while (i < self.num_points) : (i += 1) {
            const txt = std.fmt.bufPrintZ(&buf, "({d}, {d})", .{
                self.points[i][0],
                self.points[i][1],
            }) catch @panic("bufsize too small");
            if (c.igSelectable_Bool(txt, self.point_selected == i, flags, selectable_dims)) {
                self.point_selected = i;
                if (c.igIsMouseDoubleClicked_Nil(0)) {
                    self.point_selected = i;
                    const new_vec: math.vector.vec3 = .{
                        self.next_vec_data[0],
                        self.next_vec_data[1],
                        0,
                    };
                    self.addVector(new_vec, self.points[self.point_selected]);
                }
            }
        }
        c.igTreePop();
    }
}

fn drawVectors(self: *vma_ui) void {
    const scale = ui.helpers().scale;
    const selectable_dims = c.ImVec2_ImVec2_Float(100 * scale, 20 * scale).*;
    const flags = c.ImGuiSelectableFlags_SpanAvailWidth | c.ImGuiSelectableFlags_AllowDoubleClick;
    if (c.igTreeNode_Str("vectors")) {
        var i: usize = 0;
        var buf: [250]u8 = undefined;
        while (i < self.num_vectors) : (i += 1) {
            const txt = std.fmt.bufPrintZ(&buf, "({d}, {d})", .{
                self.vectors[i].vector[0],
                self.vectors[i].vector[1],
            }) catch @panic("bufsize too small");
            if (c.igSelectable_Bool(txt, false, flags, selectable_dims)) {
                if (c.igIsMouseDoubleClicked_Nil(0)) {
                    const new_vec: math.vector.vec3 = .{
                        self.next_vec_data[0],
                        self.next_vec_data[1],
                        0,
                    };
                    const vec_origin = math.vector.add(self.vectors[i].vector, self.vectors[i].origin);
                    self.addVector(new_vec, vec_origin);
                    const sum_vec = math.vector.negate(math.vector.add(new_vec, self.vectors[i].vector));
                    const sum_origin = math.vector.add(new_vec, vec_origin);
                    self.addVector(sum_vec, sum_origin);
                }
            }
        }
        c.igTreePop();
    }
}

fn addVector(self: *vma_ui, new_vec: math.vector.vec3, origin: math.vector.vec3) void {
    if (self.num_vectors + 1 == max_vectors) return;
    self.vectors[self.num_vectors] = .{
        .origin = origin,
        .vector = new_vec,
    };
    self.num_vectors += 1;
    var is_in_points = false;
    var i: usize = 0;
    const new_point = math.vector.add(new_vec, origin);
    const a: [3]f32 = new_point;
    while (i < self.num_points) : (i += 1) {
        const b: [3]f32 = self.points[i];
        if (std.mem.eql(f32, a[0..], b[0..])) {
            is_in_points = true;
            break;
        }
    }
    if (!is_in_points) {
        self.points[self.num_points] = new_point;
        self.num_points += 1;
    }
    self.clearInput();
}

fn printVectors(self: *vma_ui) void {
    var i: usize = 0;
    std.debug.print("vectors:\n", .{});
    while (i < self.num_vectors) : (i += 1) {
        std.debug.print("\torigin: ({d}, {d}) - vector: ({d}, {d})\n", .{
            self.vectors[i].origin[0],
            self.vectors[i].origin[1],
            self.vectors[i].vector[0],
            self.vectors[i].vector[1],
        });
    }
}

fn clearInput(self: *vma_ui) void {
    self.next_vec_data = .{ 0, 0, 0 };
}

fn clearData(self: *vma_ui) void {
    self.clearInput();
    self.num_vectors = 0;
    self.num_points = 1;
    self.point_selected = 0;
}

const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", {});
    @cInclude("cimgui.h");
});

const std = @import("std");
const math = @import("../../math/math.zig");
const ui = @import("../../ui/ui.zig");
