mesh: rhi.Mesh,

const Points = @This();

pub fn init(
    program: u32,
    instance_count: usize,
    label: [:0]const u8,
) Points {
    var attribute_data: [1]rhi.attributeData = undefined;

    const p0: math.vector.vec3 = .{ 0, 0, 0 };
    const n0: math.vector.vec3 = .{ 0, 1, 0 };

    attribute_data[0] = .{
        .position = p0,
        .normal = n0,
    };

    const indices: [1]u32 = .{0};
    const vao_buf = rhi.attachBuffer(attribute_data[0..], label);
    const ebo = rhi.initEBO(@ptrCast(indices[0..]), vao_buf.vao, label);
    return .{
        .mesh = .{
            .program = program,
            .vao = vao_buf.vao,
            .buffer = vao_buf.buffer,
            .instance_type = .{
                .instanced = .{
                    .index_count = indices.len,
                    .instances_count = instance_count,
                    .ebo = ebo,
                    .primitive = c.GL_POINTS,
                    .format = c.GL_UNSIGNED_INT,
                },
            },
        },
    };
}

const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
const math = @import("../math/math.zig");
