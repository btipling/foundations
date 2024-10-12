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
        const path = std.fs.path.join(allocator, &[_][]const u8{ self.path, self.names[i] }) catch @panic("OOM");
        defer allocator.free(path);
        std.debug.print("loading textures at path: {s}\n", .{path});
        self.images[i] = self.textures_loader.loadAsset(path) catch return CubemapError.LoadingFailed;
    }
}

const std = @import("std");
const Image = @import("Image.zig");
const loader = @import("loader.zig");
