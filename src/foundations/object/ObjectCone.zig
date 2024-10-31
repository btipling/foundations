mesh: rhi.Mesh,

const Cone = @This();
const num_triangles: usize = 256;
const change: f32 = std.math.pi / 128.0;
const num_vertices: usize = 4 * num_triangles;
const num_indices: usize = 3 * num_triangles;

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
    label: [:0]const u8,
) Cone {
    var d = data();

    const vao_buf = rhi.attachInstancedBuffer(d.attribute_data[0..], instance_data, label);
    const ebo = rhi.initEBO(@ptrCast(d.indices[0..]), vao_buf.vao, label);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .wire_mesh = false,
            .instance_type = .{
                .instanced = .{
                    .index_count = num_indices,
                    .instances_count = instance_data.len,
                    .ebo = ebo,
                    .primitive = c.GL_TRIANGLES,
                    .format = c.GL_UNSIGNED_INT,
                },
            },
            .cull = false,
        },
    };
}

fn data() struct { attribute_data: [num_vertices]rhi.attributeData, indices: [num_indices]u32 } {
    var attribute_data: [num_vertices]rhi.attributeData = undefined;
    var indices: [num_indices]u32 = undefined;

    const start: math.vector.vec3 = .{ 1, 0, 0 };
    var offset: usize = 0;
    var rad: f32 = 0;
    for (0..num_triangles) |_| {
        const uoffset: u32 = @intCast(offset);
        const p0: math.vector.vec3 = .{ 0, @cos(rad), @sin(rad) };
        rad += change;
        const p1: math.vector.vec3 = .{ 0, @cos(rad), @sin(rad) };
        const p2 = start;
        const tri = math.geometry.Triangle.init(p0, p1, p2);
        attribute_data[offset + 0] = .{
            .position = tri.p0,
            .normal = tri.normal,
        };
        indices[offset + 0] = uoffset + 0;
        attribute_data[uoffset + 1] = .{
            .position = tri.p1,
            .normal = tri.normal,
        };
        indices[offset + 1] = uoffset + 1;
        attribute_data[uoffset + 2] = .{
            .position = tri.p2,
            .normal = tri.normal,
        };
        indices[offset + 2] = uoffset + 2;
        offset += 3;
    }

    return .{ .attribute_data = attribute_data, .indices = indices };
}

const std = @import("std");
const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
const math = @import("../math/math.zig");
