mesh: rhi.Mesh,

const Triangle = @This();

pub const default_positions: [3][3]f32 = .{
    .{ -0.025, -0.025, 0 },
    .{ 0.0, 0.025, 0 },
    .{ 0.025, -0.025, 0 },
};

pub const default_colors: [3][4]f32 = .{
    .{ 0, 1, 0, 1 },
    .{ 0, 0, 1, 1 },
    .{ 1, 0, 0, 1 },
};

pub const default_normals: [3][3]f32 = .{
    .{ 0, -1, 0 },
    .{ 0, -1, 0 },
    .{ 0, -1, 0 },
};

pub fn init(
    allocator: std.mem.Allocator,
    vertex_partials: []const []const u8,
    frag_shader: rhi.Shader.fragment_shader_type,
    positions: [3][3]f32,
    colors: [3][4]f32,
    normals: [3][3]f32,
) Triangle {
    const program = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = program,
            .instance_data = true,
            .fragment_shader = frag_shader,
        };
        s.attach(allocator, vertex_partials);
    }
    return initWithProgram(program, positions, colors, normals);
}

pub fn initWithProgram(
    program: u32,
    positions: [3][3]f32,
    colors: [3][4]f32,
    normals: [3][3]f32,
) Triangle {
    var data: [3]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        data[i] = .{
            .position = positions[i],
            .color = colors[i],
            .normals = normals[i],
        };
    }
    const vao_buf = rhi.attachBuffer(data[0..]);
    return .{
        .mesh = .{
            .cull = false,
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .instance_type = .{
                .array = .{
                    .count = positions.len,
                },
            },
        },
    };
}

const std = @import("std");
const rhi = @import("../rhi/rhi.zig");
