mesh: rhi.mesh,
vertex_data_size: usize = 0,
instance_data_stride: usize = 0,
instanced: bool = false,

const Quad = @This();

pub const default_deprecated_positions: [6][3]f32 = .{
    .{ -1, -1, 0 },
    .{ -1, 1, 0 },
    .{ 1, -1, 0 },

    .{ -1, 1, 0 },
    .{ 1, 1, 0 },
    .{ 1, -1, 0 },
};

pub const default_correct_positions: [4][3]f32 = .{
    .{ 0, 0, 0 },
    .{ 0, 0, 1 },
    .{ 1, 0, 0 },
    .{ 1, 0, 1 },
};

pub const default_correct_indices: [6]u32 = .{
    0, 1, 2, 3, 1, 2,
};

pub fn init(
    vertex_shader: []const u8,
    frag_shader: []const u8,
    positions: [6][3]f32,
    colors: [6][4]f32,
) Quad {
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);

    var data: [6]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        data[i] = .{
            .position = positions[i],
            .color = colors[i],
        };
    }
    const vao_buf = rhi.attachBuffer(data[0..]);
    return .{
        .mesh = .{
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

pub fn initInstanced(
    program: u32,
    instance_data: []rhi.instanceData,
) Quad {
    // zig fmt: off
    const positions = default_correct_positions;
    // zig fmt: on
    var indices = default_correct_indices;

    var rhi_data: [positions.len]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < positions.len) : (i += 1) {
        rhi_data[i] = .{
            .position = positions[i],
            .color = .{ 1, 0, 1, 1 },
            .normals = .{ 1, 0, 0 },
        };
    }
    const vao_buf = rhi.attachInstancedBuffer(rhi_data[0..], instance_data);
    const ebo = rhi.initEBO(@ptrCast(indices[0..]), vao_buf.vao);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .instance_type = .{
                .instanced = .{
                    .index_count = indices.len,
                    .instances_count = instance_data.len,
                    .ebo = ebo,
                    .primitive = c.GL_TRIANGLES,
                    .format = c.GL_UNSIGNED_INT,
                },
            },
        },
        .vertex_data_size = vao_buf.vertex_data_size,
        .instance_data_stride = vao_buf.instance_data_stride,
        .instanced = true,
    };
}

pub fn updateInstanceAt(self: Quad, index: usize, instance_data: rhi.instanceData) void {
    rhi.updateInstanceData(self.mesh.buffer, self.vertex_data_size, self.instance_data_stride, index, instance_data);
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
