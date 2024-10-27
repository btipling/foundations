path: []const u8 = undefined,
absolute_path: ?[]const u8 = null,
bytes: ?[]const u8 = null,
owned: bool = true,
ctx: Generator.Ctx = undefined,

const File = @This();

const FileError = error{
    NoBytesToWriteError,
    NoPathError,
};

const max_bytes = 4096 << 12;

pub fn init(allocator: std.mem.Allocator, ctx: Generator.Ctx, path: []const u8) !*File {
    const f: *File = try allocator.create(File);
    errdefer allocator.destroy(f);

    const full_source_path = try std.fs.path.join(allocator, &[_][]const u8{ ctx.cwd, path });

    f.* = .{
        .path = path,
        .absolute_path = full_source_path,
        .ctx = ctx,
    };
    return f;
}

pub fn initWithEmbed(allocator: std.mem.Allocator, bytes: []const u8) !*File {
    const f: *File = try allocator.create(File);
    errdefer allocator.destroy(f);

    f.* = .{
        .bytes = bytes,
        .owned = false,
    };
    return f;
}

pub fn read(self: *File, allocator: std.mem.Allocator) !void {
    const absolute_path = self.absolute_path orelse return FileError.NoPathError;
    const fs = try std.fs.openFileAbsolute(absolute_path, .{});
    self.bytes = try fs.readToEndAlloc(allocator, max_bytes);
}

pub fn write(self: *File, _: std.mem.Allocator) !void {
    const absolute_path = self.absolute_path orelse return FileError.NoPathError;
    const bytes = self.bytes orelse return FileError.NoBytesToWriteError;
    const fs = try std.fs.createFileAbsolute(absolute_path, .{});
    try fs.writeAll(bytes);
}

pub fn deinit(self: *File, allocator: std.mem.Allocator) void {
    if (self.absolute_path) |absolute_path| allocator.free(absolute_path);
    if (self.owned) if (self.bytes) |b| allocator.free(b);
    allocator.destroy(self);
}

const std = @import("std");
const Generator = @import("Generator.zig");
