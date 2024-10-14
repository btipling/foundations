mesh: rhi.Mesh,
vertex_data_size: usize,
instance_data_stride: usize,

const Circle = @This();
const num_vertices: usize = 100 * 3.14;
const num_indices: usize = (num_vertices - 2) * 3;

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
) Circle {
    const d = data();

    var rhi_data: [num_vertices]rhi.attributeData = undefined;
    var i: usize = 0;
    while (i < num_vertices) : (i += 1) {
        rhi_data[i] = .{
            .position = d.positions[i],
            .color = .{ 1, 0, 1, 1 },
            .normal = .{ 1, 0, 0 },
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

pub fn updateInstanceAt(self: Circle, index: usize, instance_data: rhi.instanceData) void {
    rhi.updateInstanceData(self.mesh.buffer, self.vertex_data_size, self.instance_data_stride, index, instance_data);
}

fn data() struct { positions: [num_vertices][3]f32, indices: [num_indices]u32 } {
    const r: f32 = 1.0;
    var p: [num_vertices][3]f32 = undefined;
    var indices: [num_indices]u32 = undefined;
    // origin:
    const origin: [3]f32 = .{ 0, 0, 0 };
    p[0] = origin;
    indices[0] = 0;
    var i: usize = 1;
    var last_index: u32 = 0;
    var indices_index: usize = 1;
    const angle: f32 = std.math.pi / 100.0;
    var current_vector: [3]f32 = .{ 0, 0, r }; // start at z positive, move counter clockwise around the y axis
    while (i < num_vertices) : (i += 1) {
        if (i > 2) {
            // Complete circle every with previous index and origin
            indices[indices_index] = last_index;
            indices_index += 1;
            indices[indices_index] = 0;
            indices_index += 1;
        }
        p[i] = current_vector;
        last_index += 1;
        indices[indices_index] = last_index;
        indices_index += 1;
        const new_coordinates: [2]f32 = math.rotation.polarCoordinatesToCartesian2D(math.vector.vec2, .{
            r,
            angle * @as(f32, @floatFromInt(i)),
        });
        current_vector[2] = new_coordinates[0];
        current_vector[0] = new_coordinates[1];
    }
    return .{ .positions = p, .indices = indices };
}

const std = @import("std");
const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
const math = @import("../math/math.zig");
