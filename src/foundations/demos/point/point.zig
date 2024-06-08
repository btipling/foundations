program: u32,
vao: u32,
buffer: u32,
count: usize,

const Point = @This();

const vertex_shader: []const u8 = @embedFile("vertex.glsl");
const frag_shader: []const u8 = @embedFile("frag.glsl");

pub fn init() Point {
    const program = rhi.createProgram();
    const vao = rhi.createVAO();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    return .{
        .program = program,
        .vao = vao,
        .buffer = 0,
        .count = 1,
    };
}

pub fn deinit(self: Point) void {
    rhi.delete(self.program, self.vao, self.buffer);
}

pub fn draw(self: Point) void {
    rhi.drawPoints(self.program, self.vao, self.count);
}

const rhi = @import("../../rhi/rhi.zig");
