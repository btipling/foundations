ui_state: unit_circle_ui,
allocator: std.mem.Allocator,

const UnitCircle = @This();

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "Unit circle",
    };
}

pub fn init(allocator: std.mem.Allocator) *UnitCircle {
    const unitcircle = allocator.create(UnitCircle) catch @panic("OOM");
    unitcircle.* = .{
        .ui_state = .{},
        .allocator = allocator,
    };

    return unitcircle;
}

pub fn deinit(self: *UnitCircle, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *UnitCircle, _: f64) void {
    self.handleInput();
    self.ui_state.draw();
}

fn handleInput(_: *UnitCircle) void {
    const input = ui.input.getReadOnly() orelse return;
    _ = input;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const unit_circle_ui = @import("unit_circle_ui.zig");
const object = @import("../../object/object.zig");
