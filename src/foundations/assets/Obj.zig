data: []u8 = undefined,
file_name: []const u8 = undefined,
vertices: [max_vertices][3]f32 = undefined,
texture_coordinates: [max_vertices][2]f32 = undefined,
normals: [max_vertices][3]f32 = undefined,
num_vertices: usize = 0,
indicies: [max_indicies][3][3]usize = undefined,
num_indicies: usize = 0,

const max_vertices: usize = 100_000;
const max_indicies: usize = max_vertices * 3;

const Obj = @This();
const rgba_channels: u8 = 4;

pub fn init(self: *Obj, _: std.mem.Allocator, data: []u8, file_name: []const u8) void {
    self.data = data;
    self.file_name = file_name;
    std.debug.print("loaded object\n", .{});
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
                        self.texture_coordinates[t_index] = .{ s, t };
                        t_index += 1;
                    },
                    'n' => {
                        var nit = std.mem.tokenizeScalar(u8, line[2..], ' ');
                        const x: f32 = std.fmt.parseFloat(f32, nit.next() orelse "") catch @panic("invalid float");
                        const y: f32 = std.fmt.parseFloat(f32, nit.next() orelse "") catch @panic("invalid float");
                        const z: f32 = std.fmt.parseFloat(f32, nit.next() orelse "") catch @panic("invalid float");
                        self.normals[n_index] = .{ x, y, z };
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
                const v1: [3]usize = parseFace(i_it.next() orelse "") catch @panic("invalid index");
                const v2: [3]usize = parseFace(i_it.next() orelse "") catch @panic("invalid index");
                const v3: [3]usize = parseFace(i_it.next() orelse "") catch @panic("invalid index");
                self.indicies[i_index] = .{ v1, v2, v3 };
                i_index += 1;
            },
            else => {},
        }
    }
    self.num_vertices = v_index;
    self.num_indicies = i_index;
    std.debug.print("num_vertices: {d} num_indices: {d}\n", .{ self.num_vertices, self.num_indicies });
}

fn parseFace(face: []const u8) ![3]usize {
    var it = std.mem.tokenizeScalar(u8, face[0..], '/');
    const v: usize = std.fmt.parseInt(u32, it.next() orelse "", 10) catch @panic("invalid index");
    const t: usize = std.fmt.parseInt(u32, it.next() orelse "", 10) catch @panic("invalid index");
    const n: usize = std.fmt.parseInt(u32, it.next() orelse "", 10) catch @panic("invalid index");
    return .{ v, t, n };
}

pub fn deinit(self: *Obj, allocator: std.mem.Allocator) void {
    allocator.free(self.data);
    self.data = undefined;
    allocator.destroy(self);
}

const std = @import("std");
const c = @import("../c.zig").c;
