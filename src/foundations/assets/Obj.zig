data: []u8 = undefined,
file_name: []const u8 = undefined,
vertices: [max_vertices][3]f32 = undefined,
texture_coordinates: [max_vertices][2]f32 = undefined,
normal: [max_vertices][3]f32 = undefined,
num_vertices: usize = 0,
indicies: [max_indicies][3][3]usize = undefined,
num_indicies: usize = 0,
num_texture_coords: usize = 0,
num_normals: usize = 0,

const max_vertices: usize = 100_000;
const max_indicies: usize = max_vertices * 2;

const Obj = @This();
const rgba_channels: u8 = 4;

pub fn init(self: *Obj, _: std.mem.Allocator, data: []u8, file_name: []const u8) void {
    self.data = data;
    self.file_name = file_name;
    var lit = std.mem.tokenizeScalar(u8, data, '\n');
    var t_index: usize = 0;
    var v_index: usize = 0;
    var n_index: usize = 0;
    var i_index: usize = 0;
    while (lit.next()) |line| {
        switch (line[0]) {
            'v' => {
                switch (line[1]) {
                    't' => {
                        var tcit = std.mem.tokenizeScalar(u8, line[2..], ' ');
                        const s: f32 = std.fmt.parseFloat(f32, tcit.next() orelse "") catch @panic("invalid float");
                        const t: f32 = std.fmt.parseFloat(f32, tcit.next() orelse "") catch @panic("invalid float");
                        self.texture_coordinates[t_index] = .{ s, 1 - t };
                        t_index += 1;
                    },
                    'n' => {
                        var nit = std.mem.tokenizeScalar(u8, line[2..], ' ');
                        const x: f32 = std.fmt.parseFloat(f32, nit.next() orelse "") catch @panic("invalid float");
                        const y: f32 = std.fmt.parseFloat(f32, nit.next() orelse "") catch @panic("invalid float");
                        const z: f32 = std.fmt.parseFloat(f32, nit.next() orelse "") catch @panic("invalid float");
                        self.normal[n_index] = .{ x, y, z };
                        n_index += 1;
                    },
                    else => {
                        var vit = std.mem.tokenizeScalar(u8, line[1..], ' ');
                        const x: f32 = std.fmt.parseFloat(f32, vit.next() orelse "") catch @panic("invalid float");
                        const y: f32 = std.fmt.parseFloat(f32, vit.next() orelse "") catch @panic("invalid float");
                        const z: f32 = std.fmt.parseFloat(f32, vit.next() orelse "") catch @panic("invalid float");
                        self.vertices[v_index] = .{ x, y, z };
                        v_index += 1;
                    },
                }
            },
            'f' => {
                var i_it = std.mem.tokenizeScalar(u8, line[1..], ' ');
                const v3: [3]usize = parseFace(i_it.next() orelse "") catch @panic("invalid index");
                const v2: [3]usize = parseFace(i_it.next() orelse "") catch @panic("invalid index");
                const v1: [3]usize = parseFace(i_it.next() orelse "") catch @panic("invalid index");
                self.indicies[i_index] = .{ v1, v2, v3 };
                i_index += 1;
            },
            else => {},
        }
    }
    self.num_vertices = v_index;
    self.num_indicies = i_index;
    self.num_texture_coords = t_index;
    self.num_normals = n_index;
}

pub fn toObject(self: *Obj, prog: u32, i_datas: []rhi.instanceData, label: [:0]const u8) object.object {
    var attribute_data: [max_vertices]rhi.attributeData = undefined;
    var indices: [max_indicies]u32 = undefined;

    var current_index: usize = 0;
    for (0..self.num_indicies) |i| {
        const index_data = self.indicies[i];
        for (0..3) |j| {
            const p = self.vertices[index_data[j][0]];
            attribute_data[current_index] = .{
                .position = p,
                .normal = self.normal[index_data[j][2]],
                .texture_coords = self.texture_coordinates[index_data[j][1]],
            };
            indices[current_index] = @intCast(current_index);
            current_index += 1;
        }
    }

    const model: object.object = .{
        .obj = object.Obj.init(
            prog,
            i_datas,
            attribute_data[0..current_index],
            indices[0..current_index],
            label,
        ),
    };
    return model;
}

fn parseFace(face: []const u8) ![3]usize {
    var it = std.mem.tokenizeScalar(u8, face[0..], '/');
    const v: usize = std.fmt.parseInt(u32, it.next() orelse "", 10) catch @panic("invalid index");
    const t: usize = std.fmt.parseInt(u32, it.next() orelse "", 10) catch @panic("invalid index");
    const n: usize = std.fmt.parseInt(u32, it.next() orelse "", 10) catch @panic("invalid index");
    return .{ v - 1, t - 1, n - 1 };
}

pub fn deinit(self: *Obj, allocator: std.mem.Allocator) void {
    allocator.free(self.data);
    self.data = undefined;
    allocator.destroy(self);
}

const std = @import("std");
const c = @import("../c.zig").c;
const rhi = @import("../rhi/rhi.zig");
const object = @import("../object/object.zig");
