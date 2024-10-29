mesh: rhi.Mesh,
vertex_data_size: usize,
instance_data_stride: usize,
attribute_data: [num_vertices]rhi.attributeData,
indices: [num_indices]u32,

const Parallelepied = @This();

const num_vertices: usize = 24;
const num_indices: usize = 36; // because normal

pub const pp: math.geometry.Parallelepiped = .{
    .v0 = .{ 1, 0, 0 },
    .v1 = .{ 0, 1, 0 },
    .v2 = .{ 0, 0, 1 },
};

pub fn init(
    program: u32,
    instance_data: []const rhi.instanceData,
    label: [:0]const u8,
) Parallelepied {
    return initParallelepiped(program, instance_data, false, label);
}

pub fn initCubemap(
    program: u32,
    instance_data: []const rhi.instanceData,
    label: [:0]const u8,
) Parallelepied {
    return initParallelepiped(program, instance_data, true, label);
}

fn initParallelepiped(
    program: u32,
    instance_data: []const rhi.instanceData,
    cubemap: bool,
    label: [:0]const u8,
) Parallelepied {
    var d = data(cubemap);

    const vao_buf = rhi.attachInstancedBuffer(d.data[0..], instance_data, label);
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

fn data(cubemap: bool) struct { data: [num_vertices]rhi.attributeData, indices: [num_indices]u32 } {
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
    s_os = addSurface(&rv_data, p0, p1, p3, p4, s_os, cubemap);
    i_os = addIndicesPerSurface(&indices, 0, 1, 2, 3, i_os);
    // left origin_x_pos
    s_os = addSurface(&rv_data, p2, p5, p0, p1, s_os, cubemap);
    i_os = addIndicesPerSurface(&indices, 4, 5, 6, 7, i_os);
    // back y_pos_z_pos
    s_os = addSurface(&rv_data, p6, p7, p2, p5, s_os, cubemap);
    i_os = addIndicesPerSurface(&indices, 8, 9, 10, 11, i_os);
    // right z_pos_x_pos
    s_os = addSurface(&rv_data, p3, p4, p6, p7, s_os, cubemap);
    i_os = addIndicesPerSurface(&indices, 12, 13, 14, 15, i_os);
    // bottom origin_y_pos
    s_os = addSurface(&rv_data, p0, p3, p2, p6, s_os, cubemap);
    i_os = addIndicesPerSurfaceYZ(&indices, 16, 17, 18, 19, i_os);
    // top x_pos_y_pos
    _ = addSurface(&rv_data, p4, p1, p7, p5, s_os, cubemap);
    i_os = addIndicesPerSurfaceYZ(&indices, 20, 21, 22, 23, i_os);
    return .{ .data = rv_data, .indices = indices };
}

fn addIndicesPerSurfaceYZ(
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
    indices[offset + 2] = far_corner1;
    // second surface triangle
    indices[offset + 3] = far_corner1;
    indices[offset + 4] = shared_1;
    indices[offset + 5] = far_corner0;
    return offset + 6;
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
    indices[offset + 1] = shared_0;
    indices[offset + 2] = shared_1;
    // second surface triangle
    indices[offset + 3] = far_corner1;
    indices[offset + 4] = shared_1;
    indices[offset + 5] = shared_0;
    return offset + 6;
}

const n_dir = enum {
    x_pos,
    x_neg,
    y_pos,
    y_neg,
    z_pos,
    z_neg,
};

fn addSurface(
    s_data: *[num_vertices]rhi.attributeData,
    sp0: math.vector.vec3,
    sp1: math.vector.vec3,
    sp2: math.vector.vec3,
    sp3: math.vector.vec3,
    offset: usize,
    cubemap: bool,
) usize {
    const e1 = math.vector.sub(sp0, sp1);
    const e2 = math.vector.sub(sp0, sp2);
    const n = math.vector.normalize(math.vector.crossProduct(e1, e2));
    const sn_dir: n_dir = blk: {
        if (math.float.equal_e(
            1.0,
            math.vector.dotProduct(n, @as(@Vector(3, f32), .{ 1, 0, 0 })),
        )) {
            break :blk .x_pos;
        } else if (math.float.equal_e(
            1.0,
            math.vector.dotProduct(n, @as(@Vector(3, f32), .{ -1, 0, 0 })),
        )) {
            break :blk .x_neg;
        } else if (math.float.equal_e(
            1.0,
            math.vector.dotProduct(n, @as(@Vector(3, f32), .{ 0, 1, 0 })),
        )) {
            break :blk .y_pos;
        } else if (math.float.equal_e(
            1.0,
            math.vector.dotProduct(n, @as(@Vector(3, f32), .{ 0, -1, 0 })),
        )) {
            break :blk .y_neg;
        } else if (math.float.equal_e(
            1.0,
            math.vector.dotProduct(n, @as(@Vector(3, f32), .{ 0, 0, -1 })),
        )) {
            break :blk .z_pos;
        } else {
            break :blk .z_neg;
        }
    };
    const tc1: [2]f32 = s: switch (cubemap) {
        true => {
            switch (sn_dir) {
                .x_pos => break :s .{ 0.2511, 0.0 },
                .x_neg => break :s .{ 0.50, 1.00 },
                .y_pos => break :s .{ 0.25, 0.66666666666 },
                .y_neg => break :s .{ 0.75, 0.66666666666 },
                .z_pos => break :s .{ 0.50, 0.66666666666 },
                else => break :s .{ 0.00, 0.66666666666 },
            }
        },
        false => .{ 0, 1 },
    };
    const tc2: [2]f32 = s: switch (cubemap) {
        true => {
            switch (sn_dir) {
                .x_pos => break :s .{ 0.50, 0.0 },
                .x_neg => break :s .{ 0.2511, 1.00 },
                .y_pos => break :s .{ 0.25, 0.33333333333 },
                .y_neg => break :s .{ 0.75, 0.33433333333 },
                .z_pos => break :s .{ 0.50, 0.33333333333 },
                else => break :s .{ 0.00, 0.333333333 },
            }
        },
        false => .{ 0, 0 },
    };
    const tc3: [2]f32 = s: switch (cubemap) {
        true => {
            switch (sn_dir) {
                .x_pos => break :s .{ 0.25, 0.33333333333 },
                .x_neg => break :s .{ 0.50, 0.66666666666 }, //nope
                .y_pos => break :s .{ 0.50, 0.66666666666 },
                .y_neg => break :s .{ 1.00, 0.66666666666 },
                .z_pos => break :s .{ 0.75, 0.66666666666 },
                else => break :s .{ 0.25, 0.66666666666 },
            }
        },
        false => .{ 1, 1 },
    };
    const tc4: [2]f32 = s: switch (cubemap) {
        true => {
            switch (sn_dir) {
                .x_pos => break :s .{ 0.50, 0.333333333 },
                .x_neg => break :s .{ 0.2511, 0.66666666666 },
                .y_pos => break :s .{ 0.50, 0.33333333333 },
                .y_neg => break :s .{ 1.00, 0.33333333333 },
                .z_pos => break :s .{ 0.75, 0.33433333333 },
                else => break :s .{ 0.25, 0.33333333333 },
            }
        },
        false => .{ 1, 0 },
    };
    s_data[offset] = .{
        .position = sp0,
        .color = color.debug_color,
        .normal = n,
        .texture_coords = tc1,
    };
    s_data[offset + 1] = .{
        .position = sp1,
        .color = color.debug_color,
        .normal = n,
        .texture_coords = tc2,
    };
    s_data[offset + 2] = .{
        .position = sp2,
        .color = color.debug_color,
        .normal = n,
        .texture_coords = tc3,
    };
    s_data[offset + 3] = .{
        .position = sp3,
        .color = color.debug_color,
        .normal = n,
        .texture_coords = tc4,
    };
    return offset + 4;
}

const std = @import("std");
const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
const math = @import("../math/math.zig");
const color = @import("../color/color.zig");
