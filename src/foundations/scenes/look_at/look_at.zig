ui_state: look_at_ui,
allocator: std.mem.Allocator,
cfg: *config,

const LookAt = @This();

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .math,
        .name = "lookAt",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *LookAt {
    const lkt = allocator.create(LookAt) catch @panic("OOM");
    const ui_state: look_at_ui = .{};
    lkt.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .cfg = cfg,
    };

    return lkt;
}

pub fn deinit(self: *LookAt, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *LookAt, _: f64) void {
    self.handleInput();
    self.ui_state.draw();
}

fn handleInput(self: *LookAt) void {
    const input = ui.input.getReadOnly() orelse return;
    const x = input.coord_x orelse return;
    const z = input.coord_z orelse return;
    _ = x;
    _ = z;
    _ = self;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const look_at_ui = @import("look_at_ui.zig");
const object = @import("../../object/object.zig");
const config = @import("../../config/config.zig");
