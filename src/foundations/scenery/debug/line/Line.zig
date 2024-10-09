width: f32,
program: u32,
vao: u32,
buffer: u32,

const Line = @This();

const vertex_shader: []const u8 = @embedFile("../../../shaders/debug_vert.glsl");

pub fn init(
    allocator: std.mem.Allocator,
    start: math.vector.vec3,
    end: math.vector.vec3,
    color: math.vector.vec4,
    m: math.matrix,
    width: f32,
) Line {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .color,
        };
        s.attach(allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }

    var data: [2]rhi.attributeData = undefined;
    data[0] = .{
        .position = start,
        .color = color,
    };
    data[1] = .{
        .position = end,
        .color = color,
    };
    const vao_buf = rhi.attachBuffer(data[0..]);
    var lm: rhi.Uniform = rhi.Uniform.init(prog, "f_object_m") catch @panic("uniform failed");
    lm.setUniformMatrix(m);
    return .{
        .width = width,
        .program = prog,
        .vao = vao_buf.vao,
        .buffer = vao_buf.buffer,
    };
}

pub fn deinit(self: Line, _: std.mem.Allocator) void {
    rhi.deletePrimitive(self.program, self.vao, self.buffer);
}

pub fn draw(self: Line, _: f64) void {
    rhi.drawLines(self.program, self.vao, 2.0, self.width);
}

const std = @import("std");
const rhi = @import("../../../rhi/rhi.zig");
const math = @import("../../../math/math.zig");
