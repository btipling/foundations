// demos
demo_instances: [num_demos]ui.ui_state.demos = undefined,

ui_state: *ui.ui_state,
allocator: std.mem.Allocator,

const num_demos = 10;

const Demos = @This();

pub fn init(allocator: std.mem.Allocator, ui_state: *ui.ui_state) *Demos {
    const demos = allocator.create(Demos) catch @panic("OOM");
    errdefer allocator.destroy(demos);
    demos.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
    };
    const p = point.init(allocator);
    errdefer p.deinit(allocator);
    const ta = triangle_animated.init(allocator);
    errdefer ta.deinit(allocator);
    const mva = math_vector_arithmetic.init(allocator);
    errdefer mva.deinit(allocator);
    const pr = point_rotating.init(allocator);
    errdefer pr.deinit(allocator);
    const t = triangle.init(allocator);
    errdefer t.deinit(allocator);
    const lcs = linear_colorspace.init(allocator);
    errdefer lcs.deinit(allocator);
    const ca = cubes_animated.init(allocator);
    errdefer ca.deinit(allocator);
    const circ = circle.init(allocator);
    errdefer circ.deinit(allocator);
    const sp = sphere.init(allocator);
    errdefer sp.deinit(allocator);
    const li = line.init(allocator);
    errdefer li.deinit(allocator);

    demos.demo_instances[@intFromEnum(demo_type.point)] = .{ .point = p };
    demos.demo_instances[@intFromEnum(demo_type.point_rotating)] = .{ .point_rotating = pr };
    demos.demo_instances[@intFromEnum(demo_type.triangle)] = .{ .triangle = t };
    demos.demo_instances[@intFromEnum(demo_type.triangle_animated)] = .{ .triangle_animated = ta };
    demos.demo_instances[@intFromEnum(demo_type.math_vector_arithmetic)] = .{ .math_vector_arithmetic = mva };
    demos.demo_instances[@intFromEnum(demo_type.linear_colorspace)] = .{ .linear_colorspace = lcs };
    demos.demo_instances[@intFromEnum(demo_type.cubes_animated)] = .{ .cubes_animated = ca };
    demos.demo_instances[@intFromEnum(demo_type.circle)] = .{ .circle = circ };
    demos.demo_instances[@intFromEnum(demo_type.sphere)] = .{ .sphere = sp };
    demos.demo_instances[@intFromEnum(demo_type.line)] = .{ .line = li };
    return demos;
}

pub fn deinit(self: *Demos) void {
    comptime var i: usize = 0;
    inline while (i < num_demos - 1) : (i += 1) self.deinitDemo(i);
    self.allocator.destroy(self);
}

fn deinitDemo(self: Demos, i: usize) void {
    switch (self.demo_instances[i]) {
        inline else => |d| d.deinit(self.allocator),
    }
}

pub fn drawDemo(self: Demos, frame_time: f64) void {
    switch (self.demo_instances[@intFromEnum(self.ui_state.demo_current)]) {
        inline else => |d| d.draw(frame_time),
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
