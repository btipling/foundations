x_line: Line = undefined,
y_line: Line = undefined,
z_line: Line = undefined,

const Cross = @This();

const vertex_shader: []const u8 = @embedFile("../../../shaders/debug_vert.glsl");

pub fn init(
    allocator: std.mem.Allocator,
    m: math.matrix,
    width: f32,
) Cross {
    const x_line = Line.init(
        allocator,
        .{ 0, 0, 0 },
        .{ 1, 0, 0 },
        .{ 1, 0, 0, 1 },
        m,
        width,
        "x_line",
    );
    const y_line = Line.init(
        allocator,
        .{ 0, 0, 0 },
        .{ 0, 1, 0 },
        .{ 0, 1, 0, 1 },
        m,
        width,
        "y_line",
    );
    const z_line = Line.init(
        allocator,
        .{ 0, 0, 0 },
        .{ 0, 0, 1 },
        .{ 0, 0, 1, 1 },
        m,
        width,
        "z_line",
    );
    return .{
        .x_line = x_line,
        .y_line = y_line,
        .z_line = z_line,
    };
}

pub fn deinit(self: Cross, allocator: std.mem.Allocator) void {
    self.x_line.deinit(allocator);
    self.y_line.deinit(allocator);
    self.z_line.deinit(allocator);
}

pub fn draw(self: Cross, dt: f64) void {
    self.x_line.draw(dt);
    self.y_line.draw(dt);
    self.z_line.draw(dt);
}

const std = @import("std");
const math = @import("../../../math/math.zig");
const Line = @import("../line/Line.zig");
