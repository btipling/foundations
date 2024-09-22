mesh: rhi.Mesh,
vertex_data_size: usize,
instance_data_stride: usize,
attribute_data: [num_vertices]rhi.attributeData,
indices: [num_indices]u32,

const Pyramid = @This();

const num_vertices: usize = 24;
const num_indices: usize = 36;

// zig fmt: off
pub const pp: math.geometry.Pyramid = .{
};
// zig fmt: on

pub fn init(
    program: u32,
    instance_data: []rhi.instanceData,
    blend: bool,
) Pyramid {
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
pub fn updateInstanceAt(self: Pyramid, index: usize, instance_data: rhi.instanceData) void {
    rhi.updateInstanceData(self.mesh.buffer, self.vertex_data_size, self.instance_data_stride, index, instance_data);
}

fn data() struct { data: [num_vertices]rhi.attributeData, indices: [num_indices]u32 } {
    var rv_data: [num_vertices]rhi.attributeData = undefined;
    var indices: [num_indices]u32 = undefined;
    const p0: [3]f32 = .{ 1.5, 0, 0 };
    const p1: [3]f32 = .{ 0, -1, 1 };
    const p2: [3]f32 = .{ 0, 1, 1 };
    const p3: [3]f32 = .{ 0, 1, -1 };
    const p4: [3]f32 = .{ 0, -1, -1 };
    var s_os: usize = 0;
    var i_os: usize = 0;
    // front origin_z_pos
    const texture_face: [3][2]f32 = .{ .{ 0.5, 1 }, .{ 1, 0 }, .{ 0, 0 } };
    const texture_floor: [4][2]f32 = .{ .{ 0, 1 }, .{ 1, 1 }, .{ 0, 0 }, .{ 1, 0 } };
    s_os = addSurface(&rv_data, p0, p1, p2, s_os, texture_face);
    i_os = addIndicesPerSurface(&indices, 0, 1, 2, i_os);
    // left origin_x_pos
    s_os = addSurface(&rv_data, p0, p2, p3, s_os, texture_face);
    i_os = addIndicesPerSurface(&indices, 3, 4, 5, i_os);
    // back y_pos_z_pos
    s_os = addSurface(&rv_data, p0, p3, p4, s_os, texture_face);
    i_os = addIndicesPerSurface(&indices, 6, 7, 8, i_os);
    // right z_pos_x_pos
    s_os = addSurface(&rv_data, p0, p4, p1, s_os, texture_face);
    i_os = addIndicesPerSurface(&indices, 9, 10, 11, i_os);
    // top x_pos_y_pos
    _ = addBottomSurface(&rv_data, p1, p2, p4, p3, s_os, texture_floor);
    i_os = addBottomIndicesPerSurface(
        &indices,
        12,
        13,
        14,
        15,
        i_os,
    );

    return .{ .data = rv_data, .indices = indices };
}

fn addIndicesPerSurface(
    indices: *[num_indices]u32,
    origin: u32,
    left: u32,
    right: u32,
    offset: usize,
) usize {
    // first surface triangle
    indices[offset] = origin;
    indices[offset + 2] = left;
    indices[offset + 1] = right;
    return offset + 3;
}

fn addSurface(
    s_data: *[num_vertices]rhi.attributeData,
    sp0: math.vector.vec3,
    sp1: math.vector.vec3,
    sp2: math.vector.vec3,
    offset: usize,
    texture_coords: [3][2]f32,
) usize {
    const e1 = math.vector.sub(sp0, sp1);
    const e2 = math.vector.sub(sp0, sp2);
    const n = math.vector.normalize(math.vector.crossProduct(e2, e1));
    s_data[offset] = .{
        .position = sp0,
        .color = color.debug_color,
        .normals = n,
        .texture_coords = texture_coords[0],
    };
    s_data[offset + 1] = .{
        .position = sp1,
        .color = color.debug_color,
        .normals = n,
        .texture_coords = texture_coords[1],
    };
    s_data[offset + 2] = .{
        .position = sp2,
        .color = color.debug_color,
        .normals = n,
        .texture_coords = texture_coords[2],
    };
    return offset + 3;
}

fn addBottomIndicesPerSurface(
    indices: *[num_indices]u32,
    far_corner0: u32,
    shared_0: u32,
    shared_1: u32,
    far_corner1: u32,
    offset: usize,
) usize {
    // first surface triangle
    indices[offset] = far_corner0;
    indices[offset + 1] = shared_0;
    indices[offset + 2] = shared_1;
    // second surface triangle
    indices[offset + 3] = far_corner1;
    indices[offset + 4] = shared_1;
    indices[offset + 5] = shared_0;
    return offset + 6;
}

fn addBottomSurface(
    s_data: *[num_vertices]rhi.attributeData,
    sp0: math.vector.vec3,
    sp1: math.vector.vec3,
    sp2: math.vector.vec3,
    sp3: math.vector.vec3,
    offset: usize,
    texture_coords: [4][2]f32,
) usize {
    const e1 = math.vector.sub(sp0, sp1);
    const e2 = math.vector.sub(sp0, sp2);
    const n = math.vector.normalize(math.vector.crossProduct(e1, e2));
    s_data[offset] = .{
        .position = sp0,
        .color = color.debug_color,
        .normals = n,
        .texture_coords = texture_coords[0],
    };
    s_data[offset + 1] = .{
        .position = sp1,
        .color = color.debug_color,
        .normals = n,
        .texture_coords = texture_coords[1],
    };
    s_data[offset + 2] = .{
        .position = sp2,
        .color = color.debug_color,
        .normals = n,
        .texture_coords = texture_coords[2],
    };
    s_data[offset + 3] = .{
        .position = sp3,
        .color = color.debug_color,
        .normals = n,
        .texture_coords = texture_coords[3],
    };
    return offset + 4;
}

const std = @import("std");
const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
const math = @import("../math/math.zig");
const color = @import("../color/color.zig");
