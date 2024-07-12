point: ?*point = null,
ui_state: line_ui,
allocator: std.mem.Allocator,

const Line = @This();

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Line",
    };
}

pub fn init(allocator: std.mem.Allocator) *Line {
    const line = allocator.create(Line) catch @panic("OOM");

    line.* = .{
        .ui_state = .{},
        .allocator = allocator,
    };

    return line;
}

pub fn deinit(self: *Line, allocator: std.mem.Allocator) void {
    if (self.point) |p| p.deinit(allocator);
    allocator.destroy(self);
}

pub fn draw(self: *Line, _: f64) void {
    self.handleInput();
    if (self.point) |p| {
        p.draw();
    }
    self.ui_state.draw();
}

fn handleOver(self: *Line) ?usize {
    const root_point = self.point orelse return null;
    clear_highlight: {
        const input = ui.input.get() orelse break :clear_highlight;
        const x = input.mouse_x orelse break :clear_highlight;
        const z = input.mouse_z orelse break :clear_highlight;
        const px = point.coordinate(x);
        const pz = point.coordinate(z);
        if (root_point.getAt(px, pz)) |p| {
            root_point.highlight(p.index);
            return p.index;
        }
    }
    root_point.clearHighlight();
    return null;
}

fn handleInput(self: *Line) void {
    const p_index = self.handleOver();
    const input = ui.input.getReadOnly() orelse return;
    const button = input.mouse_button orelse return;
    const action = input.mouse_action orelse return;
    const x = input.mouse_x orelse return;
    const z = input.mouse_z orelse return;
    if (action == c.GLFW_RELEASE) if (self.point) |p| {
        p.release();
        return;
    };
    if (p_index) |pi| {
        if (self.point) |p| {
            if (button == c.GLFW_MOUSE_BUTTON_1) p.startDragging(pi);
        }
    }
    if (action != c.GLFW_PRESS) return;
    if (button != c.GLFW_MOUSE_BUTTON_1) return;
    self.addPoint(x, z);
}

fn addPoint(self: *Line, x: f32, z: f32) void {
    if (self.point) |p| {
        if (p.drag(x, z)) return;
        p.addAt(self.allocator, x, z);
        return;
    }
    const np = point.initRoot(self.allocator, x, z);
    self.point = np;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const line_ui = @import("line_ui.zig");
const object = @import("../../object/object.zig");
const point = @import("point.zig");
