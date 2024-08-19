mesh: rhi.mesh,

const Triangle = @This();

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
) Triangle {
    var attribute_data: [3]rhi.attributeData = undefined;

    const p0: math.vector.vec3 = .{ 0, 0, 0 };
    const p1: math.vector.vec3 = .{ 0, 0, 1 };
    const p2: math.vector.vec3 = .{ 1, 0, 0 };

    const triangle = math.geometry.Triangle.init(p0, p1, p2);
    attribute_data[0] = .{
        .position = triangle.p0,
        .normals = triangle.normal,
    };
    attribute_data[1] = .{
        .position = triangle.p1,
        .normals = triangle.normal,
    };
    attribute_data[2] = .{
        .position = triangle.p2,
        .normals = triangle.normal,
    };

    const indices: [3]u32 = .{ 0, 1, 2 };
    const vao_buf = rhi.attachInstancedBuffer(attribute_data[0..], instance_data);
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
    };
}

const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
