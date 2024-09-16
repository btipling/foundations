mesh: rhi.Mesh,
vertex_data_size: usize,
instance_data_stride: usize,

const Sphere = @This();
const precision: usize = 48;
const precision_f: f32 = @floatFromInt(precision);
const num_vertices = (precision + 1) * (precision + 1);
const num_indices = precision * precision * 6;

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
    wireframe: bool,
) Sphere {
    var d = data();

    const vao_buf = rhi.attachInstancedBuffer(d.attribute_data[0..], instance_data);
    const ebo = rhi.initEBO(@ptrCast(d.indices[0..]), vao_buf.vao);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .wire_mesh = wireframe,
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

pub fn updateInstanceAt(self: Sphere, index: usize, instance_data: rhi.instanceData) void {
    rhi.updateInstanceData(self.mesh.buffer, self.vertex_data_size, self.instance_data_stride, index, instance_data);
}

fn data() struct { attribute_data: [num_vertices]rhi.attributeData, indices: [num_indices]u32 } {
    var attribute_data: [num_vertices]rhi.attributeData = undefined;
    var indices: [num_indices]u32 = undefined;

    const p_index: usize = precision + 1;

    for (0..p_index) |i| {
        const i_f: f32 = @floatFromInt(i);
        for (0..p_index) |j| {
            const j_f: f32 = @floatFromInt(j);
            const half_circle: f32 = std.math.pi;
            const full_circle: f32 = std.math.pi * 2;
            const x: f32 = @cos(half_circle - i_f * std.math.pi / precision_f);
            const phi: f32 = @abs(@cos(std.math.asin(x)));
            const theta: f32 = j_f * full_circle / precision_f;
            const z = -@cos(theta) * phi;
            const y = @sin(theta) * phi;
            const pos: [3]f32 = .{ x, y, z };
            const index: usize = i * p_index + j;
            attribute_data[index] = .{
                .position = pos,
                .normals = .{ x, y, z },
                .texture_coords = .{ j_f / precision_f, i_f / precision_f },
            };
        }
    }
    for (0..(precision)) |i| {
        const inext: usize = i + 1;

        const i_pindex: usize = i * p_index;
        const inext_pindex: usize = inext * p_index;
        const i_precision: usize = i * precision;

        for (0..(precision)) |j| {
            const jnext: usize = j + 1;

            const i_j_pindex = i_pindex + j;
            const i_jnext_pindex = i_pindex + jnext;
            const inext_j_pindex = inext_pindex + j;
            const inext_jnext_pindex = inext_pindex + jnext;

            const v1: u32 = @intCast(i_j_pindex);
            const v2: u32 = @intCast(i_jnext_pindex);
            const v3: u32 = @intCast(inext_j_pindex);
            const v4: u32 = @intCast(inext_jnext_pindex);

            const offset = 6 * (i_precision + j);

            indices[offset + 0] = v1;
            indices[offset + 1] = v2;
            indices[offset + 2] = v3;

            indices[offset + 3] = v2;
            indices[offset + 4] = v4;
            indices[offset + 5] = v3;
        }
    }

    return .{ .attribute_data = attribute_data, .indices = indices };
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
