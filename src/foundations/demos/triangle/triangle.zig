program: u32,
vao: u32,
buffer: u32,

const Triangle = @This();

const positions: [3][3]f32 = .{
    .{ 0, 1, 0.5 },
    .{ 0, 0, 0.5 },
    .{ 1, 0, 0.5 },
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
    };
}

pub fn deinit() void {}

pub fn draw() void {}

const rhi = @import("../../rhi/rhi.zig");
