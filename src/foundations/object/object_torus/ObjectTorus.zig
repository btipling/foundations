mesh: rhi.Mesh,
vertex_data_size: usize,
instance_data_stride: usize,

const Torus = @This();
const precision: usize = 48;
const precision_f: f32 = @floatFromInt(precision);
const num_vertices = (precision + 1) * (precision + 1);
const num_indices = precision * precision * 6;
const inner_radius: f32 = 0.5;
const outer_radius: f32 = 0.2;

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
    wireframe: bool,
) Torus {
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

pub fn updateInstanceAt(self: Torus, index: usize, instance_data: rhi.instanceData) void {
    rhi.updateInstanceData(self.mesh.buffer, self.vertex_data_size, self.instance_data_stride, index, instance_data);
}

fn data() struct { attribute_data: [num_vertices]rhi.attributeData, indices: [num_indices]u32 } {
    var attribute_data: [num_vertices]rhi.attributeData = undefined;
    var indices: [num_indices]u32 = undefined;

    const p_index: usize = precision + 1;
    for (0..p_index) |i| {
        const i_f: f32 = @floatFromInt(i);
        const phi: f32 = i_f * std.math.tau / precision_f;

        var m: math.matrix = math.matrix.rotationY(phi);
        var p1: math.vector.vec4 = .{ outer_radius, 0.0, 0.0, 1.0 };
        p1 = math.matrix.transformVector(m, p1);
        const p2: math.vector.vec4 = math.vector.add(p1, @as(math.vector.vec4, .{ 0.0, 0.0, inner_radius, 0.0 }));

        const vertex: [3]f32 = .{ p2[0], p2[1], p2[2] };

        const texture_coords: [2]f32 = .{ 0.0, i_f / precision_f };

        //TODO: support tangents in vertex attributes
        m = math.matrix.transformMatrix(m, math.matrix.rotationY(phi + (std.math.pi / 2.0)));
        var tv: math.vector.vec4 = .{ -1.0, 0.0, 0.0, 1.0 };
        tv = math.matrix.transformVector(m, tv);
        const t_tangent: math.vector.vec3 = .{ tv[0], tv[1], tv[2] };
        const s_tangent: math.vector.vec3 = .{ 0, -1, 0 };
        const normals = math.vector.normalize(math.vector.crossProduct(t_tangent, s_tangent));
        attribute_data[i] = .{
            .position = vertex,
            .normals = normals,
            .texture_coords = texture_coords,
        };
    }

    for (1..p_index) |ring| {
        const ring_f: f32 = @floatFromInt(ring);
        const phi: f32 = ring_f * std.math.tau / precision_f;
        // float amt = (float)toRadians((float)ring * 360.0f / (prec));
        const m: math.matrix = math.matrix.rotationX(phi);
        for (0..p_index) |i| {
            const index = ring * p_index + i;

            const ad = attribute_data[i];
            const p = ad.position;
            var v1: math.vector.vec4 = .{ p[0], p[1], p[2], 0 };
            v1 = math.matrix.transformVector(m, v1);
            const vertex: [3]f32 = .{ v1[0], v1[1], v1[2] };

            const texture_coords: [2]f32 = .{ ring_f * 2.0 / precision_f, ad.texture_coords[1] };

            // TODO: support tangents in vertex attributes
            // s and t tangents need to be created here

            const n = ad.normals;
            var n1: math.vector.vec4 = .{ n[0], n[1], n[2], 0 };
            n1 = math.matrix.transformVector(m, n1);
            const normals: math.vector.vec3 = .{ n1[0], n1[1], n1[2] };
            attribute_data[index] = .{
                .position = vertex,
                .normals = math.vector.normalize(normals),
                .texture_coords = texture_coords,
            };
        }
    }

    // calculate triangle indices
    for (0..precision) |ring| {
        for (0..precision) |i| {
            const offset = (ring * precision + i) * 2;
            indices[offset * 3 + 0] = @intCast(ring * (precision + 1) + i);
            indices[offset * 3 + 2] = @intCast((ring + 1) * (precision + 1) + i);
            indices[offset * 3 + 1] = @intCast(ring * (precision + 1) + i + 1);
            indices[(offset + 1) * 3 + 0] = @intCast(ring * (precision + 1) + i + 1);
            indices[(offset + 1) * 3 + 2] = @intCast((ring + 1) * (precision + 1) + i);
            indices[(offset + 1) * 3 + 1] = @intCast((ring + 1) * (precision + 1) + i + 1);
        }
    }

    return .{ .attribute_data = attribute_data, .indices = indices };
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
