program: u32,
vao: u32,
buffer: u32,
count: usize,
ctx: scenes.SceneContext,

const AnimatedTriangle = @This();

const vertex_shader: []const u8 = @embedFile("vertex.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Triangle animated",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *AnimatedTriangle {
    const prog = rhi.createProgram();
    const vao = rhi.createVAO();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = false,
            .fragment_shader = .color,
        };
        s.attach(allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }

    const at = allocator.create(AnimatedTriangle) catch @panic("OOM");
    at.* = .{
        .program = prog,
        .vao = vao,
        .buffer = 0,
        .count = 3,
        .ctx = ctx,
    };
    return at;
}

pub fn deinit(self: *AnimatedTriangle, allocator: std.mem.Allocator) void {
    rhi.deletePrimitive(self.program, self.vao, self.buffer);
    allocator.destroy(self);
}

const animation_duration: f64 = 2; // seconds

pub fn draw(self: *AnimatedTriangle, frame_time: f64) void {
    const is_even = @mod(@floor(frame_time / animation_duration), 2) == 0;
    const pos: f32 = @floatCast((@mod(frame_time, animation_duration) / animation_duration));
    var x: f32 = pos * 2 - 1;
    if (is_even) {
        x = 1 - pos * 2;
    }
    rhi.setUniform1f(self.program, "f_offset", x);
    rhi.drawArrays(self.program, self.vao, self.count);
    rhi.setUniformMatrix(self.program, "f_transform", math.matrix.orthographicProjection(
        0,
        9,
        0,
        6,
        self.ctx.cfg.near,
        self.ctx.cfg.far,
    ));
}

const std = @import("std");
const rhi = @import("../../../rhi/rhi.zig");
const ui = @import("../../../ui/ui.zig");
const scenes = @import("../../scenes.zig");
const math = @import("../../../math/math.zig");
