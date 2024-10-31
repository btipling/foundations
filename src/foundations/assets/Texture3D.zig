data: []u8 = undefined,
file_name: []const u8 = undefined,

const Texture3D = @This();

pub fn init(self: *Texture3D, _: std.mem.Allocator, data: []u8, file_name: []const u8) void {
    self.data = data;
    self.file_name = file_name;
}

pub fn deinit(self: *Texture3D, allocator: std.mem.Allocator) void {
    allocator.free(self.data);
    self.data = undefined;
    allocator.destroy(self);
}

const std = @import("std");
const c = @import("../c.zig").c;
