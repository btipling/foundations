path: []const u8,
names: [6][]const u8 = undefined,
images: [6]*Image = undefined,
textures_loader: *loader.Loader(Image),

const Cubemap = @This();

pub const CubemapError = error{
    LoadingFailed,
};

pub fn loadAll(self: *Cubemap, allocator: std.mem.Allocator) CubemapError!void {
    for (0..6) |i| {
        var parts: [2][]const u8 = undefined;
        parts[0] = self.path;
        parts[1] = self.names[i];
        const path = std.mem.concat(allocator, u8, parts[0..]) catch @panic("OOM");
        defer allocator.free(path);
        self.images[i] = self.textures_loader.loadAsset(path) catch return CubemapError.LoadingFailed;
    }
}

const std = @import("std");
const Image = @import("Image.zig");
const loader = @import("loader.zig");
