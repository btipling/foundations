mesh: rhi.Mesh,
vertex_data_size: usize,
instance_data_stride: usize,

const Obj = @This();
const max_vertices = 100_000;
const max_indicies = max_vertices * 3;

pub fn init(
    program: u32,
    vertices: [][3]f32,
    texture_coordinates: [][2]f32,
    normals: [][3]f32,
    indicies: [][3][3]usize,
    instance_data: []rhi.instanceData,
) Obj {
    var d = data(vertices, texture_coordinates, normals, indicies);
    // The Obj loader creates a vertex for every index currently.
    const vao_buf = rhi.attachInstancedBuffer(d.attribute_data[0..d.num_indices], instance_data);
    const ebo = rhi.initEBO(@ptrCast(d.indices[0..d.num_indices]), vao_buf.vao);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .instance_type = .{
                .instanced = .{
                    .index_count = d.num_indices,
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

fn data(
    vertices: [][3]f32,
    texture_coordinates: [][2]f32,
    normals: [][3]f32,
    obj_indicies: [][3][3]usize,
) struct { attribute_data: [max_vertices]rhi.attributeData, indices: [max_indicies]u32, num_indices: usize } {
    var attribute_data: [max_vertices]rhi.attributeData = undefined;
    var indices: [max_indicies]u32 = undefined;

    for (obj_indicies, 0..) |index_data, i| {
        attribute_data[i] = .{
            .position = vertices[index_data[0]],
            .normals = normals[index_data[2]],
            .texture_coords = texture_coordinates[index_data[1]],
        };
        indices[i] = i;
    }

    return .{ .attribute_data = attribute_data, .indices = indices, .num_indices = obj_indicies.len };
}

const std = @import("std");
const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
const math = @import("../math/math.zig");
