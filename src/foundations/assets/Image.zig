width: f32 = 0,
height: f32 = 0,
data: []u8 = undefined,
file_name: []const u8 = undefined,

const Image = @This();

pub fn init(self: *Image, data: []u8, file_name: []const u8) void {
    self.data = data;
    self.file_name = file_name;
}

pub fn deinit(self: *Image, allocator: std.mem.Allocator) void {
    allocator.free(self.data);
    self.data = undefined;
    allocator.destroy(self);
}

const std = @import("std");
