line_manager: *manager = undefined,
ui_state: *line_ui,
allocator: std.mem.Allocator,
ctx: scenes.SceneContext,
ortho_persp: math.matrix,

const Line = @This();

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Line",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Line {
    const line = allocator.create(Line) catch @panic("OOM");
    const ui_state = line_ui.init(allocator);
    const ortho_persp = math.matrix.orthographicProjection(
        0,
        9,
        0,
        6,
        ctx.cfg.near,
        ctx.cfg.far,
    );
    line.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .line_manager = manager.init(allocator, ui_state, ctx.cfg),
        .ctx = ctx,
        .ortho_persp = ortho_persp,
    };

    return line;
}

pub fn deinit(self: *Line, allocator: std.mem.Allocator) void {
    self.line_manager.deinit(allocator);
    self.ui_state.deinit(allocator);
    allocator.destroy(self);
}

pub fn draw(self: *Line, _: f64) void {
    self.handleInput();
    self.line_manager.draw();
    self.ui_state.draw();
}

fn handleOver(self: *Line) ?usize {
    const root_point = self.line_manager.rootPoint() orelse return null;
    clear_highlight: {
        const input = ui.input.get() orelse break :clear_highlight;
        const x = input.coord_x orelse break :clear_highlight;
        const z = input.coord_z orelse break :clear_highlight;
        const px = point.coordinate(x);
        const pz = point.coordinate(z);
        if (root_point.getAt(px * 3.0, pz * 4.5)) |p| {
            self.line_manager.highlight(p.index);
            return p.index;
        }
    }
    self.line_manager.clearHighlight();
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
    const x = input.coord_x orelse return;
    const z = input.coord_z orelse return;
    if (action == c.GLFW_RELEASE) {
        self.line_manager.release();
        return;
    }
    if (p_index) |pi| {
        if (button == c.GLFW_MOUSE_BUTTON_1) self.line_manager.startDragging(pi);
    }
    if (action != c.GLFW_PRESS) return;
    if (button != c.GLFW_MOUSE_BUTTON_1) return;
    self.addPoint(x * 3, z * 4.5, tangent);
}

fn addPoint(self: *Line, x: f32, z: f32, tangent: bool) void {
    if (self.line_manager.drag(x, z)) return;
    self.line_manager.addAt(self.allocator, x, z, tangent);
}

const std = @import("std");
const c = @import("../../../c.zig").c;
const ui = @import("../../../ui/ui.zig");
const rhi = @import("../../../rhi/rhi.zig");
const line_ui = @import("LineUI.zig");
const point = @import("LinePoint.zig");
const manager = @import("LineManager.zig");
const math = @import("../../../math/math.zig");
const scenes = @import("../../scenes.zig");
