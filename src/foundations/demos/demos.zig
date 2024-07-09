// demos
demo_instance: ?ui.ui_state.demos = null,

allocator: std.mem.Allocator,

const Demos = @This();

pub fn init(allocator: std.mem.Allocator) *Demos {
    const demos = allocator.create(Demos) catch @panic("OOM");
    errdefer allocator.destroy(demos);
    demos.* = .{
        .allocator = allocator,
    };
    demos.initDemo(ui.ui_state.demo_type.line);
    return demos;
}

pub fn setDemo(self: *Demos, dt: ui.ui_state.demo_type) void {
    if (self.demo_instance) |cdt| if (cdt == dt) return;
    self.deinitDemo();
    self.initDemo(dt);
}

pub fn deinit(self: *Demos) void {
    self.deinitDemo();
    self.allocator.destroy(self);
}

fn initDemo(self: *Demos, dt: ui.ui_state.demo_type) void {
    self.demo_instance = switch (dt) {
        inline else => |dtag| @unionInit(ui.ui_state.demos, @tagName(dtag), std.meta.Child(
            std.meta.TagPayload(
                ui.ui_state.demos,
                dtag,
            ),
        ).init(self.allocator)),
    };
}

fn deinitDemo(self: Demos) void {
    if (self.demo_instance) |di| {
        switch (di) {
            inline else => |d| d.deinit(self.allocator),
        }
    }
}

pub fn drawDemo(self: Demos, frame_time: f64) void {
    if (self.demo_instance) |di| {
        switch (di) {
            inline else => |d| d.draw(frame_time),
        }
    }
}

const std = @import("std");
const ui = @import("../ui/ui.zig");
const demo_type = ui.ui_state.demo_type;
const point = @import("point/point.zig");
const point_rotating = @import("point_rotating/point_rotating.zig");
const triangle = @import("triangle/triangle.zig");
const triangle_animated = @import("triangle_animated/triangle_animated.zig");
const math_vector_arithmetic = @import("math_vector_arithmetic/math_vector_arithmetic.zig");
const linear_colorspace = @import("linear_colorspace/linear_colorspace.zig");
const cubes_animated = @import("cubes_animated/cubes_animated.zig");
const circle = @import("circle/circle.zig");
const sphere = @import("sphere/sphere.zig");
const line = @import("line/line.zig");
