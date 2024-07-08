objects: [100]object.object = undefined,
num_objects: usize = 0,
point: ?*point = null,
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

fn handleInput(self: *Line) void {
    const input = ui.input.get() orelse return;
    const button = input.mouse_button orelse return;
    const action = input.mouse_action orelse return;
    if (button != c.GLFW_MOUSE_BUTTON_1) return;
    std.debug.print("button: {any} action: {any} x: {any} z:{any}\n", .{
        input.mouse_button,
        input.mouse_action,
        input.mouse_x,
        input.mouse_z,
    });
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
        if (p.addAt(self.allocator, px, pz, x, z)) |np| {
            self.objects[self.num_objects] = np.circle;
            self.num_objects += 1;
            std.debug.print("no: {d}\n", .{self.num_objects});
            return;
        }
        return;
    }
    const np = point.init(self.allocator, px, pz, x, z);
    self.point = np;
    self.objects[self.num_objects] = np.circle;
    self.num_objects += 1;
    std.debug.print("initial no: {d}\n", .{self.num_objects});
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const line_ui = @import("line_ui.zig");
const object = @import("../../object/object.zig");
const point = @import("point.zig");
