mesh: rhi.mesh,
vertex_data_size: usize,
instance_data_stride: usize,
attribute_data: [num_vertices]rhi.attributeData,
indices: [num_indices]u32,

const Parallelepied = @This();

const num_vertices: usize = 24;
const num_indices: usize = 36; // because normals

pub const pp: math.geometry.Parallelepiped = .{
    .v0 = .{ 1, 0, 0 },
    .v1 = .{ 0, 1, 0 },
    .v2 = .{ 0, 0, 1 },
};

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
    blend: bool,
) Parallelepied {
    var d = data();

    const vao_buf = rhi.attachInstancedBuffer(d.data[0..], instance_data);
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
            .blend = blend,
        },
        .vertex_data_size = vao_buf.vertex_data_size,
        .instance_data_stride = vao_buf.instance_data_stride,
        .attribute_data = d.data,
        .indices = d.indices,
    };
}
pub fn updateInstanceAt(self: Parallelepied, index: usize, instance_data: rhi.instanceData) void {
    rhi.updateInstanceData(self.mesh.buffer, self.vertex_data_size, self.instance_data_stride, index, instance_data);
}

fn data() struct { data: [num_vertices]rhi.attributeData, indices: [num_indices]u32 } {
    var rv_data: [num_vertices]rhi.attributeData = undefined;
    var indices: [num_indices]u32 = undefined;
    const origin: [3]f32 = .{ 0, 0, 0 };
    const p0 = origin;
    const p1 = pp.v0;
    const p2 = pp.v1;
    const p3 = pp.v2;
    const p4 = math.vector.add(p1, p3);
    const p5 = math.vector.add(p1, p2);
    const p6 = math.vector.add(p2, p3);
    const p7 = math.vector.add(p1, p6);
    var s_os: usize = 0;
    var i_os: usize = 0;
    // front origin_z_pos
    s_os = addSurface(&rv_data, p0, p1, p3, p4, s_os);
    i_os = addIndicesPerSurface(&indices, 0, 1, 2, 3, i_os);
    // left origin_x_pos
    s_os = addSurface(&rv_data, p2, p5, p0, p1, s_os);
    i_os = addIndicesPerSurface(&indices, 4, 5, 6, 7, i_os);
    // back y_pos_z_pos
    s_os = addSurface(&rv_data, p6, p7, p2, p5, s_os);
    i_os = addIndicesPerSurface(&indices, 8, 9, 10, 11, i_os);
    // right z_pos_x_pos
    s_os = addSurface(&rv_data, p3, p4, p6, p7, s_os);
    i_os = addIndicesPerSurface(&indices, 12, 13, 14, 15, i_os);
    // bottom origin_y_pos
    s_os = addSurface(&rv_data, p0, p3, p2, p6, s_os);
    i_os = addIndicesPerSurface(&indices, 16, 17, 18, 19, i_os);
    // top x_pos_y_pos
    _ = addSurface(&rv_data, p4, p1, p7, p5, s_os);
    i_os = addIndicesPerSurface(&indices, 20, 21, 22, 23, i_os);
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
    const e1 = math.vector.sub(sp0, sp1);
    const e2 = math.vector.sub(sp0, sp2);
    const n = math.vector.normalize(math.vector.crossProduct(e1, e2));
    s_data[offset] = .{
        .position = sp0,
        .color = color.debug_color,
        .normals = n,
    };
    s_data[offset + 1] = .{
        .position = sp1,
        .color = color.debug_color,
        .normals = n,
    };
    s_data[offset + 2] = .{
        .position = sp2,
        .color = color.debug_color,
        .normals = n,
    };
    s_data[offset + 3] = .{
        .position = sp3,
        .color = color.debug_color,
        .normals = n,
    };
    return offset + 4;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const rhi = @import("../../rhi/rhi.zig");
const math = @import("../../math/math.zig");
const color = @import("../../color/color.zig");
