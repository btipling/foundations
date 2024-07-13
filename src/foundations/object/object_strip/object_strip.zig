mesh: rhi.mesh,
vertex_data_size: usize,
instance_data_stride: usize,

const Strip = @This();
const num_vertices: usize = 100 * 3.14;
const num_indices: usize = (num_vertices - 2) * 3;

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
) Strip {
    // zig fmt: off
    const d: [3][3]f32 = .{
        .{ -1, -1,  0 },
        .{  1, -1,  0 },
        .{  0,  1,  0 },
    };
    // zig fmt: on

    var rhi_data: [num_vertices]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < num_vertices) : (i += 1) {
        rhi_data[i] = .{
            .position = d.positions[i],
            .color = .{ 1, 0, 1, 1 },
            .normals = .{ 1, 0, 0 },
        };
    }
    const vao_buf = rhi.attachInstancedBuffer(rhi_data[0..], instance_data);
    const ebo = rhi.initEBO(@ptrCast(d.indices[0..]), vao_buf.vao);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .instance_type = .{
                .instanced = .{
                    .index_count = num_indices,
                    .instances_count = instance_data.len,
                    .ebo = ebo,
                    .primitive = c.GL_TRIANGLES,
                    .format = c.GL_UNSIGNED_INT,
                },
            },
        },
        .vertex_data_size = vao_buf.vertex_data_size,
        .instance_data_stride = vao_buf.instance_data_stride,
    };
}

pub fn updateInstanceAt(self: Strip, index: usize, instance_data: rhi.instanceData) void {
    rhi.updateInstanceData(self.mesh.buffer, self.vertex_data_size, self.instance_data_stride, index, instance_data);
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
