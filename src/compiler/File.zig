path: []const u8,
bytes: ?[]const u8 = null,
ctx: Compiler.Ctx = undefined,

const File = @This();

const max_bytes = 4096 << 12;

pub fn init(allocator: std.mem.Allocator, ctx: Compiler.Ctx, path: []const u8) !*File {
    const f: *File = try allocator.create(File);
    errdefer allocator.destroy(f);

    const full_source_path = try std.fs.path.join(allocator, &[_][]const u8{ ctx.cwd, path });

    std.debug.print("file path {s}\n", .{full_source_path});

    f.* = .{
        .path = full_source_path,
        .ctx = ctx,
    };
    return f;
}

pub fn read(self: *File, allocator: std.mem.Allocator) !void {
    const fs = try std.fs.openFileAbsolute(self.path, .{});
    self.bytes = try fs.readToEndAlloc(allocator, max_bytes);
}

pub fn deinit(self: *File, allocator: std.mem.Allocator) void {
    allocator.free(self.path);
    if (self.bytes) |b| allocator.free(b);
    allocator.destroy(self);
}

const std = @import("std");
const Compiler = @import("Compiler.zig");
