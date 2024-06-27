program: u32,
vao: u32,
buffer: u32,
count: usize,
linear_colorspace: bool = true,

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

pub const normals: [36][3]f32 = .{
    // z pos
    .{ 0, 0, 1 },
    .{ 0, 0, 1 },
    .{ 0, 0, 1 },
    .{ 0, 0, 1 },
    .{ 0, 0, 1 },
    .{ 0, 0, 1 },

    // z neg
    .{ 0, 0, -1 },
    .{ 0, 0, -1 },
    .{ 0, 0, -1 },
    .{ 0, 0, -1 },
    .{ 0, 0, -1 },
    .{ 0, 0, -1 },

    // y pos
    .{ 0, 1, 0 },
    .{ 0, 1, 0 },
    .{ 0, 1, 0 },
    .{ 0, 1, 0 },
    .{ 0, 1, 0 },
    .{ 0, 1, 0 },

    // y neg
    .{ 0, -1, 0 },
    .{ 0, -1, 0 },
    .{ 0, -1, 0 },
    .{ 0, -1, 0 },
    .{ 0, -1, 0 },
    .{ 0, -1, 0 },

    // x pos
    .{ 1, 0, 0 },
    .{ 1, 0, 0 },
    .{ 1, 0, 0 },
    .{ 1, 0, 0 },
    .{ 1, 0, 0 },
    .{ 1, 0, 0 },

    // x neg
    .{ -1, 0, 0 },
    .{ -1, 0, 0 },
    .{ -1, 0, 0 },
    .{ -1, 0, 0 },
    .{ -1, 0, 0 },
    .{ -1, 0, 0 },
};

pub fn init(
    program: u32,
    positions: [36][3]f32,
    color: [4]f32,
) Quad {
    var data: [36]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        data[i] = .{
            .position = positions[i],
            .color = color,
            .normals = normals[i],
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
