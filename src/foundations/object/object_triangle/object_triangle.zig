program: u32,
vao: u32,
buffer: u32,
count: usize,

const Triangle = @This();

const positions: [3][3]f32 = .{
    .{ -1, -1, 0 },
    .{ 1, -1, 0 },
    .{ 0, 0, 0 },
};

const colors: [3][4]f32 = .{
    .{ 0, 1, 0, 1 },
    .{ 0, 0, 1, 1 },
    .{ 1, 0, 0, 1 },
};

pub fn init(vertex_shader: []const u8, frag_shader: []const u8) Triangle {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    var data: [3]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        data[i] = .{
            .position = positions[i],
            .color = colors[i],
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
