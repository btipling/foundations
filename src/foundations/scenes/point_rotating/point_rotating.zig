program: u32,
vao: u32,
buffer: u32,
count: usize,
ui_state: pr_ui,
cfg: *config,

const RotatingPoint = @This();

const vertex_shader: []const u8 = @embedFile("point_rotating_vertex.glsl");
const frag_shader: []const u8 = @embedFile("point_rotating_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .shape,
        .name = "Point Rotating",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *RotatingPoint {
    const program = rhi.createProgram();
    const vao = rhi.createVAO();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    const p = allocator.create(RotatingPoint) catch @panic("OOM");
    p.* = .{
        .program = program,
        .vao = vao,
        .buffer = 0,
        .count = 1,
        .ui_state = .{
            .r = 0.9,
            .rotation_time = 3,
        },
        .cfg = cfg,
    };
    return p;
}

pub fn deinit(self: *RotatingPoint, allocator: std.mem.Allocator) void {
    rhi.deletePrimitive(self.program, self.vao, self.buffer);
    allocator.destroy(self);
}

pub fn draw(self: *RotatingPoint, frame_time: f64) void {
    const ft: f32 = @floatCast(frame_time);
    const rot = @mod(ft, self.ui_state.rotation_time) / self.ui_state.rotation_time;
    const angle_radiants: f32 = @as(f32, @floatCast(rot)) * std.math.pi * 2;
    const xy = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec2, .{ self.ui_state.r, angle_radiants });
    rhi.setUniformVec2(self.program, "f_rotating_point", xy);
    rhi.drawPoints(self.program, self.vao, self.count);
    self.ui_state.draw();
}

const std = @import("std");
const pr_ui = @import("point_rotating_ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const ui = @import("../../ui/ui.zig");
const config = @import("../../config/config.zig");
