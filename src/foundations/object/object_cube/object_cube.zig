program: u32,
vao: u32,
buffer: u32,
count: usize,
linear_colorspace: bool = false,

const Quad = @This();

pub const default_positions: [6][3]f32 = .{
    .{ -1, -1, 0 },
    .{ -1, 1, 0 },
    .{ 1, -1, 0 },

    .{ -1, 1, 0 },
    .{ 1, 1, 0 },
    .{ 1, -1, 0 },
};

pub fn init(
    vertex_shader: []const u8,
    frag_shader: []const u8,
    positions: [6][3]f32,
    color: [4]f32,
) Quad {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    var data: [6]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        data[i] = .{
            .position = positions[i],
            .color = color,
        };
    }
    const vao_buf = rhi.attachBuffer(data[0..]);
    return .{
        .program = program,
        .vao = vao_buf.vao,
        .buffer = vao_buf.buffer,
        .count = positions.len,
    };
}

const rhi = @import("../../rhi/rhi.zig");
