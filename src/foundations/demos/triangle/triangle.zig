program: u32,
vao: u32,
buffer: u32,
count: usize,

const Triangle = @This();

const positions: [3][3]f32 = .{
    .{ 0, 1, 0 },
    .{ 0, 0, 0 },
    .{ 1, 0, 0 },
};

const vertex_shader: []const u8 = @embedFile("vertex.glsl");
const frag_shader: []const u8 = @embedFile("frag.glsl");

pub fn init() Triangle {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    const vao_buf = rhi.attachBuffer(positions[0..]);
    return .{
        .program = program,
        .vao = vao_buf.vao,
        .buffer = vao_buf.buffer,
        .count = positions.len,
    };
}

pub fn deinit(self: Triangle) void {
    rhi.delete(self.program, self.vao, self.buffer);
}

pub fn draw(self: Triangle) void {
    rhi.drawArrays(self.program, self.vao, self.count);
}

const rhi = @import("../../rhi/rhi.zig");
