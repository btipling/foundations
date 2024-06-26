// demos
point: *point,
point_rotating: *point_rotating,
triangle: triangle,
triangle_animated: *triangle_animated,
math_vector_arithmetic: *math_vector_arithmetic,
linear_colorspace: *linear_colorspace,

ui_state: *ui.ui_state,
allocator: std.mem.Allocator,

const Demos = @This();

pub fn init(allocator: std.mem.Allocator, ui_state: *ui.ui_state) *Demos {
    const demos = allocator.create(Demos) catch @panic("OOM");
    demos.* = .{
        .point = point.init(allocator),
        .point_rotating = point_rotating.init(allocator),
        .triangle = triangle.init(),
        .triangle_animated = triangle_animated.init(allocator),
        .math_vector_arithmetic = math_vector_arithmetic.init(allocator),
        .linear_colorspace = linear_colorspace.init(allocator),
        .ui_state = ui_state,
        .allocator = allocator,
    };
    return demos;
}

pub fn deinit(self: *Demos) void {
    self.linear_colorspace.deinit(self.allocator);
    self.math_vector_arithmetic.deinit(self.allocator);
    self.point.deinit(self.allocator);
    self.point_rotating.deinit(self.allocator);
    self.triangle.deinit();
    self.triangle_animated.deinit(self.allocator);
    self.allocator.destroy(self);
}

pub fn drawDemo(self: Demos, frame_time: f64) void {
    switch (self.ui_state.demo_current) {
        .point => self.point.draw(),
        .point_rotating => self.point_rotating.draw(frame_time),
        .triangle => self.triangle.draw(),
        .triangle_animated => self.triangle_animated.draw(frame_time),
        .math_vector_arithmetic => self.math_vector_arithmetic.draw(frame_time),
        .linear_colorspace => self.linear_colorspace.draw(frame_time),
        else => {},
    }
}

const std = @import("std");
const ui = @import("../ui/ui.zig");
const point = @import("point/point.zig");
const point_rotating = @import("point_rotating/point_rotating.zig");
const triangle = @import("triangle/triangle.zig");
const triangle_animated = @import("triangle_animated/triangle_animated.zig");
const math_vector_arithmetic = @import("math_vector_arithmetic/math_vector_arithmetic.zig");
const linear_colorspace = @import("linear_colorspace/linear_colorspace.zig");
