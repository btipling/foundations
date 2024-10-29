mesh: rhi.Mesh,
vertex_data_size: usize,
instance_data_stride: usize,
attribute_data: [3]rhi.attributeData,

const InstancedTriangle = @This();

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
    label: [:0]const u8,
) InstancedTriangle {
    var attribute_data: [3]rhi.attributeData = undefined;

    const p0: math.vector.vec3 = .{ 0, 0, 0 };
    const p1: math.vector.vec3 = .{ 0, 0, 1 };
    const p2: math.vector.vec3 = .{ 1, 0, 0 };

    const triangle = math.geometry.Triangle.init(p0, p1, p2);
    attribute_data[0] = .{
        .position = triangle.p0,
        .normal = triangle.normal,
    };
    attribute_data[1] = .{
        .position = triangle.p1,
        .normal = triangle.normal,
    };
    attribute_data[2] = .{
        .position = triangle.p2,
        .normal = triangle.normal,
    };

    const indices: [3]u32 = .{ 0, 1, 2 };
    const vao_buf = rhi.attachInstancedBuffer(attribute_data[0..], instance_data, label);
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
        .vertex_data_size = vao_buf.vertex_data_size,
        .instance_data_stride = vao_buf.instance_data_stride,
        .attribute_data = attribute_data,
    };
}

pub fn updateInstanceAt(self: InstancedTriangle, index: usize, instance_data: rhi.instanceData) void {
    rhi.updateInstanceData(self.mesh.buffer, self.vertex_data_size, self.instance_data_stride, index, instance_data);
}

const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
const math = @import("../math/math.zig");
