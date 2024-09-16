data: []u8 = undefined,
file_name: []const u8 = undefined,

const Image = @This();
const rgba_channels: u8 = 4;

pub fn init(self: *Image, data: []u8, file_name: []const u8) void {
    self.data = data;
    self.file_name = file_name;
    std.debug.print("loaded object\n", .{});
}

pub fn deinit(self: *Image, allocator: std.mem.Allocator) void {
    allocator.free(self.data);
    self.data = undefined;
    allocator.destroy(self);
}

const std = @import("std");
const c = @import("../c.zig").c;
