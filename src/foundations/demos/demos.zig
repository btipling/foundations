triangle: triangle,
ui_state: *ui.ui_state,
allocator: std.mem.Allocator,

const Demos = @This();

pub fn init(allocator: std.mem.Allocator, ui_state: *ui.ui_state) *Demos {
    const demos = allocator.create(Demos) catch @panic("OOM");
    demos.* = .{
        .triangle = triangle.init(),
        .ui_state = ui_state,
        .allocator = allocator,
    };
    return demos;
}

pub fn deinit(self: *Demos) void {
    self.triangle.deinit();
    self.allocator.destroy(self);
}

pub fn drawDemo(self: Demos) void {
    switch (self.ui_state.demo_current) {
        .triangle => self.triangle.draw(),
        else => {},
    }
}

const std = @import("std");
const ui = @import("../ui/ui.zig");
const triangle = @import("triangle/triangle.zig");
