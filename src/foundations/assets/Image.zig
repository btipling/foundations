width: u32 = 0,
height: u32 = 0,
data: []u8 = undefined,
file_name: []const u8 = undefined,
stb_data: []u8,

const Image = @This();
const rgba_channels: u8 = 4;

pub fn init(self: *Image, _: std.mem.Allocator, data: []u8, file_name: []const u8) void {
    var x: c_int = undefined;
    var y: c_int = undefined;
    var ch: c_int = undefined;
    const ptr = c.stbi_load_from_memory(
        data.ptr,
        @as(c_int, @intCast(data.len)),
        &x,
        &y,
        &ch,
        @as(c_int, @intCast(rgba_channels)),
    );
    if (ptr == null) @panic("image loading failed");
    self.data = data;
    self.file_name = file_name;
    self.width = @as(u32, @intCast(x));
    self.height = @as(u32, @intCast(y));
    const bytes_per_row = self.width * @as(u32, @intCast(ch));
    self.stb_data = @as([*]u8, @ptrCast(ptr))[0 .. self.height * bytes_per_row];
}

pub fn deinit(self: *Image, allocator: std.mem.Allocator) void {
    c.stbi_image_free(@ptrCast(self.stb_data));
    allocator.free(self.data);
    self.data = undefined;
    allocator.destroy(self);
}

const std = @import("std");
const c = @import("../c.zig").c;
