// demos
point: *point,
triangle: triangle,
triangle_animated: *triangle_animated,

ui_state: *ui.ui_state,
allocator: std.mem.Allocator,

const Demos = @This();

pub fn init(allocator: std.mem.Allocator, ui_state: *ui.ui_state) *Demos {
    const demos = allocator.create(Demos) catch @panic("OOM");
    demos.* = .{
        .point = point.init(allocator),
        .triangle = triangle.init(),
        .triangle_animated = triangle_animated.init(allocator),
        .ui_state = ui_state,
        .allocator = allocator,
    };
    return demos;
}

pub fn deinit(self: *Demos) void {
    self.point.deinit(self.allocator);
    self.triangle.deinit();
    self.triangle_animated.deinit(self.allocator);
    self.allocator.destroy(self);
}

pub fn drawDemo(self: Demos, _: f64) void {
    switch (self.ui_state.demo_current) {
        .point => self.point.draw(),
        .triangle => self.triangle.draw(),
        .triangle_animated => self.triangle_animated.draw(),
        else => {},
    }
}

const std = @import("std");
const ui = @import("../ui/ui.zig");
const point = @import("point/point.zig");
const triangle = @import("triangle/triangle.zig");
const triangle_animated = @import("triangle_animated/triangle_animated.zig");
