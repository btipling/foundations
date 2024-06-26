program: u32,
vao: u32,
buffer: u32,
count: usize,
linear_colorspace: bool = false,

const Quad = @This();

pub const default_positions: [36][3]f32 = .{
    // z pos
    .{ -1, -1, 1 },
    .{ -1, 1, 1 },
    .{ 1, -1, 1 },
    .{ -1, 1, 1 },
    .{ 1, 1, 1 },
    .{ 1, -1, 1 },

    // z neg
    .{ -1, -1, -1 },
    .{ -1, 1, -1 },
    .{ 1, -1, -1 },
    .{ -1, 1, -1 },
    .{ 1, 1, -1 },
    .{ 1, -1, -1 },

    // y pos
    .{ -1, 1, -1 },
    .{ -1, 1, 1 },
    .{ 1, 1, -1 },
    .{ -1, 1, 1 },
    .{ 1, 1, 1 },
    .{ 1, 1, -1 },

    // y neg
    .{ -1, -1, -1 },
    .{ -1, -1, 1 },
    .{ 1, -1, -1 },
    .{ -1, -1, 1 },
    .{ 1, -1, 1 },
    .{ 1, -1, -1 },

    // x pos
    .{ 1, -1, -1 },
    .{ 1, -1, 1 },
    .{ 1, 1, -1 },
    .{ 1, -1, 1 },
    .{ 1, 1, 1 },
    .{ 1, 1, -1 },

    // x neg
    .{ -1, -1, -1 },
    .{ -1, -1, 1 },
    .{ -1, 1, -1 },
    .{ -1, -1, 1 },
    .{ -1, 1, 1 },
    .{ -1, 1, -1 },
};

pub fn init(
    vertex_shader: []const u8,
    frag_shader: []const u8,
    positions: [36][3]f32,
    color: [4]f32,
) Quad {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    var data: [36]rhi.attributeData = undefined;
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
