mesh: rhi.mesh,

const Cone = @This();
const num_vertices: usize = 3;
const num_indices: usize = 3;

pub fn init(
    program: u32,
) Cone {
    const d = data();

    const vao_buf = rhi.attachBuffer(d.attribute_data[0..]);
    const ebo = rhi.initEBO(@ptrCast(d.indices[0..]), vao_buf.vao);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .wire_mesh = false,
            .instance_type = .{
                .element = .{
                    .count = num_indices,
                    .ebo = ebo,
                    .primitive = c.GL_TRIANGLES,
                    .format = c.GL_UNSIGNED_INT,
                },
            },
        },
    };
}

fn data() struct { attribute_data: [num_vertices]rhi.attributeData, indices: [num_indices]u32 } {
    var attribute_data: [num_vertices]rhi.attributeData = undefined;
    var indices: [num_indices]u32 = undefined;

    const p0: math.vector.vec3 = .{ 0, 0, 1 };
    const p1: math.vector.vec3 = .{ 0.5, 0, 0.5 };
    const p2: math.vector.vec3 = .{ 0, 0, 0 };
    const tri = math.geometry.Triangle.init(p0, p1, p2);
    attribute_data[0] = .{
        .position = tri.p0,
        .normals = tri.normal,
    };
    indices[0] = 0;
    attribute_data[1] = .{
        .position = tri.p1,
        .normals = tri.normal,
    };
    indices[1] = 1;
    attribute_data[2] = .{
        .position = tri.p2,
        .normals = tri.normal,
    };
    indices[2] = 2;

    return .{ .attribute_data = attribute_data, .indices = indices };
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
