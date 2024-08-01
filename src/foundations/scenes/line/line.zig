manager: *manager = undefined,
ui_state: *line_ui,
allocator: std.mem.Allocator,
cfg: *config,

const Line = @This();

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Line",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *Line {
    const line = allocator.create(Line) catch @panic("OOM");
    const ui_state = line_ui.init(allocator);
    line.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .manager = manager.init(allocator, ui_state),
        .cfg = cfg,
    };

    return line;
}

pub fn deinit(self: *Line, allocator: std.mem.Allocator) void {
    self.manager.deinit(allocator);
    self.ui_state.deinit(allocator);
    allocator.destroy(self);
}

pub fn draw(self: *Line, _: f64) void {
    self.handleInput();
    self.manager.draw();
    self.ui_state.draw();
}

fn handleOver(self: *Line) ?usize {
    const root_point = self.manager.rootPoint() orelse return null;
    clear_highlight: {
        const input = ui.input.get() orelse break :clear_highlight;
        const x = input.mouse_x orelse break :clear_highlight;
        const z = input.mouse_z orelse break :clear_highlight;
        const px = point.coordinate(x);
        const pz = point.coordinate(z);
        if (root_point.getAt(px, pz)) |p| {
            self.manager.highlight(p.index);
            return p.index;
        }
    }
    self.manager.clearHighlight();
    return null;
}

fn handleInput(self: *Line) void {
    const p_index = self.handleOver();
    const input = ui.input.getReadOnly() orelse return;
    const button = input.mouse_button orelse return;
    const action = input.mouse_action orelse return;
    var tangent = false;
    if (input.mouse_mods) |m| {
        tangent = self.ui_state.mode == .hermite and m == c.GLFW_MOD_CONTROL;
    }
    const x = input.mouse_x orelse return;
    const z = input.mouse_z orelse return;
    if (action == c.GLFW_RELEASE) {
        self.manager.release();
        return;
    }
    if (p_index) |pi| {
        if (button == c.GLFW_MOUSE_BUTTON_1) self.manager.startDragging(pi);
    }
    if (action != c.GLFW_PRESS) return;
    if (button != c.GLFW_MOUSE_BUTTON_1) return;
    self.addPoint(x, z, tangent);
}

fn addPoint(self: *Line, x: f32, z: f32, tangent: bool) void {
    if (self.manager.drag(x, z)) return;
    self.manager.addAt(self.allocator, x, z, tangent);
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const line_ui = @import("line_ui.zig");
const point = @import("line_point.zig");
const manager = @import("line_manager.zig");
const config = @import("../../config/config.zig");
