objects: [100]object.object = undefined,
num_objects: usize = 0,
point: ?*point = null,
highlighted_point: ?usize = null,
ui_state: line_ui,
allocator: std.mem.Allocator,

const Line = @This();

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
    if (self.num_objects > 0) rhi.drawObjects(self.objects[0..self.num_objects]);
    self.ui_state.draw();
}

fn handleOver(self: *Line) bool {
    if (self.highlighted_point) |hp| {
        rhi.setUniformVec4(
            self.objects[hp].circle.mesh.program,
            "f_highlighted_color",
            .{ 1, 1, 1, 1 },
        );
    }
    self.highlighted_point = null;
    const input = ui.input.get() orelse return false;
    const root_point = self.point orelse return false;
    const x = input.mouse_x orelse return false;
    const z = input.mouse_z orelse return false;
    const px = point.coordinate(x);
    const pz = point.coordinate(z);
    if (root_point.getAt(px, pz)) |p| {
        const hp = p.index;
        rhi.setUniformVec4(
            self.objects[hp].circle.mesh.program,
            "f_highlighted_color",
            .{ 1, 0, 1, 1 },
        );
        self.highlighted_point = hp;
        return true;
    }
    return false;
}

fn handleInput(self: *Line) void {
    if (self.handleOver()) return;
    const input = ui.input.get() orelse return;
    const button = input.mouse_button orelse return;
    const action = input.mouse_action orelse return;
    if (button != c.GLFW_MOUSE_BUTTON_1) return;
    if (action != c.GLFW_PRESS) return;
    const x = input.mouse_x orelse return;
    const z = input.mouse_z orelse return;
    self.addPoint(x, z);
}

fn addPoint(self: *Line, x: f32, z: f32) void {
    if (self.num_objects == self.objects.len) return;
    const px = point.coordinate(x);
    const pz = point.coordinate(z);
    if (self.point) |p| {
        if (p.addAt(self.allocator, px, pz, x, z, self.num_objects)) |np| {
            self.objects[self.num_objects] = np.circle;
            self.num_objects += 1;
            return;
        }
        return;
    }
    const np = point.init(self.allocator, px, pz, x, z, self.num_objects);
    self.point = np;
    self.objects[self.num_objects] = np.circle;
    self.num_objects += 1;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const line_ui = @import("line_ui.zig");
const object = @import("../../object/object.zig");
const point = @import("point.zig");
