mesh: rhi.Mesh,
vertex_data_size: usize,
instance_data_stride: usize,

const Cylinder = @This();

const num_sides = 160;
const num_vertices: usize = 4 * num_sides;
const num_indices: usize = 6 * num_sides; // because normal

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
    label: [:0]const u8,
) Cylinder {
    var d = data();

    const vao_buf = rhi.attachInstancedBuffer(d.data[0..], instance_data, label);
    const ebo = rhi.initEBO(@ptrCast(d.indices[0..]), vao_buf.vao, label);
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
pub fn updateInstanceAt(self: Cylinder, index: usize, instance_data: rhi.instanceData) void {
    rhi.updateInstanceData(self.mesh.buffer, self.vertex_data_size, self.instance_data_stride, index, instance_data);
}

fn data() struct { data: [num_vertices]rhi.attributeData, indices: [num_indices]u32 } {
    var rv_data: [num_vertices]rhi.attributeData = undefined;
    var indices: [num_indices]u32 = undefined;
    const origin: [3]f32 = .{ 0, 0, 0 };
    const pp: math.geometry.Parallelepiped = .{
        .v0 = .{ 1, 0, 0 },
        .v1 = .{ 0, 1, 0 },
        .v2 = .{ 0, 0, 1 },
    };
    var p0: math.vector.vec3 = origin;
    var p1: math.vector.vec3 = pp.v0;
    var p2: math.vector.vec3 = pp.v2;
    var p3: math.vector.vec3 = math.vector.add(p1, p2);
    var s_os: usize = 0;
    var i_os: usize = 0;
    {
        var m = math.matrix.identity();
        m = math.matrix.transformMatrix(m, math.matrix.scale(1, 1, 0.0125));
        p0 = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(p0)));
        p1 = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(p1)));
        p2 = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(p2)));
        p3 = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(p3)));
    }

    var offset: u32 = 0;
    for (0..num_sides) |_| {
        var m = math.matrix.identity();
        m = math.matrix.transformMatrix(m, math.matrix.translate(0, 0, 0.0125));
        m = math.matrix.transformMatrix(m, math.matrix.rotationX(0.0125 * std.math.pi));
        p0 = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(p0)));
        p1 = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(p1)));
        p2 = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(p2)));
        p3 = math.vector.vec4ToVec3(math.matrix.transformVector(m, math.vector.vec3ToVec4Point(p3)));
        s_os = addSurface(&rv_data, p0, p1, p2, p3, s_os);
        i_os = addIndicesPerSurface(&indices, offset, offset + 1, offset + 2, offset + 3, i_os);
        offset += 4;
    }
    return .{ .data = rv_data, .indices = indices };
}

fn addIndicesPerSurface(
    indices: *[num_indices]u32,
    far_corner0: u32,
    shared_0: u32,
    shared_1: u32,
    far_corner1: u32,
    offset: usize,
) usize {
    // first surface triangle
    indices[offset] = far_corner0;
    indices[offset + 1] = shared_1;
    indices[offset + 2] = shared_0;
    // second surface triangle
    indices[offset + 3] = far_corner1;
    indices[offset + 4] = shared_0;
    indices[offset + 5] = shared_1;
    return offset + 6;
}

fn addSurface(
    s_data: *[num_vertices]rhi.attributeData,
    sp0: math.vector.vec3,
    sp1: math.vector.vec3,
    sp2: math.vector.vec3,
    sp3: math.vector.vec3,
    offset: usize,
) usize {
    const e1 = math.vector.sub(sp2, sp1);
    const e2 = math.vector.sub(sp0, sp2);
    const n = math.vector.normalize(math.vector.crossProduct(e2, e1));
    s_data[offset] = .{
        .position = sp0,
        .color = color.debug_color,
        .normal = n,
    };
    s_data[offset + 1] = .{
        .position = sp1,
        .color = color.debug_color,
        .normal = n,
    };
    s_data[offset + 2] = .{
        .position = sp2,
        .color = color.debug_color,
        .normal = n,
    };
    s_data[offset + 3] = .{
        .position = sp3,
        .color = color.debug_color,
        .normal = n,
    };
    return offset + 4;
}

const std = @import("std");
const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
const math = @import("../math/math.zig");
const color = @import("../color/color.zig");
