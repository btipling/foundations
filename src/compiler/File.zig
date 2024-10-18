path: []const u8 = undefined,
absolute_path: []const u8 = undefined,
bytes: ?[]const u8 = null,
ctx: Compiler.Ctx = undefined,

const File = @This();

const FileError = error{
    NoBytesToWriteError,
};

const max_bytes = 4096 << 12;

pub fn init(allocator: std.mem.Allocator, ctx: Compiler.Ctx, path: []const u8) !*File {
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

pub fn read(self: *File, allocator: std.mem.Allocator) !void {
    const fs = try std.fs.openFileAbsolute(self.absolute_path, .{});
    self.bytes = try fs.readToEndAlloc(allocator, max_bytes);
}

pub fn write(self: *File, _: std.mem.Allocator) !void {
    const bytes = self.bytes orelse return FileError.NoBytesToWriteError;
    const fs = try std.fs.createFileAbsolute(self.absolute_path, .{});
    try fs.writeAll(bytes);
}

pub fn deinit(self: *File, allocator: std.mem.Allocator) void {
    allocator.free(self.absolute_path);
    if (self.bytes) |b| allocator.free(b);
    allocator.destroy(self);
}

const std = @import("std");
const Compiler = @import("Compiler.zig");
