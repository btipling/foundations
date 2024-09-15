program: u32,
vao: u32,
buffer: u32,
count: usize,
ctx: scenes.SceneContext,

x: f32 = 0,
inc: f32 = 0.01,

const Point = @This();

const vertex_shader: []const u8 = @embedFile("vertex.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Point",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Point {
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

    const p = allocator.create(Point) catch @panic("OOM");
    p.* = .{
        .program = prog,
        .vao = vao,
        .buffer = 0,
        .count = 1,
        .ctx = ctx,
    };
    return p;
}

pub fn deinit(self: *Point, allocator: std.mem.Allocator) void {
    rhi.deletePrimitive(self.program, self.vao, self.buffer);
    allocator.destroy(self);
}

pub fn draw(self: *Point, _: f64) void {
    self.x += self.inc;
    if (self.x >= 1) {
        self.inc = -self.inc;
    }
    if (self.x < -1) {
        self.inc = -self.inc;
    }
    rhi.setUniform1f(self.program, "f_offset", self.x);
    rhi.drawPoints(self.program, self.vao, self.count);
}

const std = @import("std");
const rhi = @import("../../../rhi/rhi.zig");
const ui = @import("../../../ui/ui.zig");
const scenes = @import("../../scenes.zig");
