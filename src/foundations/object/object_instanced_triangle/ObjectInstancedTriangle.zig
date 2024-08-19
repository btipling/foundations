mesh: rhi.mesh,

const Triangle = @This();

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
) Triangle {
    var attribute_data: [3]rhi.attributeData = undefined;
    var i: usize = 0;

    const positions: [3][3]f32 = .{
        .{ 0, 0, 0 },
        .{ 0, 0, 1 },
        .{ 0.5, 0, 0.5 },
    };
    while (i < attribute_data.len) : (i += 1) {
        attribute_data[i] = .{
            .position = positions[i],
        };
    }
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

const rhi = @import("../../rhi/rhi.zig");
const c = @import("../../c.zig").c;
