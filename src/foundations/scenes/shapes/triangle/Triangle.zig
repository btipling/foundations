program: u32,
vao: u32,
buffer: u32,
count: usize,
ctx: scenes.SceneContext,

const Triangle = @This();

const positions: [3][3]f32 = .{
    .{ -0.5, 0.5, 0.5 },
    .{ 0.5, -0.5, 0.5 },
    .{ -0.5, -0.5, 0.5 },
};

const colors: [3][4]f32 = .{
    .{ 0, 1, 0, 1 },
    .{ 0, 0, 1, 1 },
    .{ 1, 0, 0, 1 },
};

const vertex_shader: []const u8 = @embedFile("vertex.glsl");
const frag_shader: []const u8 = @embedFile("frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .shape,
        .name = "Triangle",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Triangle {
    const t = allocator.create(Triangle) catch @panic("OOM");
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    var data: [3]rhi.attributeData = undefined;
    var i: usize = 0;
    const m = math.matrix.orthographicProjection(
        0,
        9,
        0,
        6,
        ctx.cfg.near,
        ctx.cfg.far,
    );
    while (i < data.len) : (i += 1) {
        const p = math.vector.vec4ToVec3(
            math.matrix.transformVector(m, math.vector.vec3ToVec4Point(positions[i])),
        );
        data[i] = .{
            .position = p,
            .color = colors[i],
        };
    }
    const vao_buf = rhi.attachBuffer(data[0..]);
    t.* = .{
        .program = program,
        .vao = vao_buf.vao,
        .buffer = vao_buf.buffer,
        .count = positions.len,
        .ctx = ctx,
    };
    return t;
}

pub fn deinit(self: *Triangle, allocator: std.mem.Allocator) void {
    rhi.deletePrimitive(self.program, self.vao, self.buffer);
    allocator.destroy(self);
}

pub fn draw(self: *Triangle, _: f64) void {
    rhi.drawArrays(self.program, self.vao, self.count);
}

const std = @import("std");
const rhi = @import("../../../rhi/rhi.zig");
const ui = @import("../../../ui/ui.zig");
const scenes = @import("../../scenes.zig");
const math = @import("../../../math/math.zig");
