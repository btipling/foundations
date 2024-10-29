mesh: rhi.Mesh,

const Obj = @This();
const max_vertices = 50_000;
const max_indicies = max_vertices * 3;

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
    attribute_data: []rhi.attributeData,
    indices: []u32,
    label: [:0]const u8,
) Obj {
    const vao_buf = rhi.attachInstancedBuffer(attribute_data, instance_data, label);
    const ebo = rhi.initEBO(@ptrCast(indices), vao_buf.vao);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .linear_colorspace = false,
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
    };
}

const std = @import("std");
const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
const math = @import("../math/math.zig");
