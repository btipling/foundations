path: []const u8,
bytes: []const u8 = undefined,
ctx: Compiler.Ctx = undefined,

const File = @This();

pub fn init(allocator: std.mem.Allocator, ctx: Compiler.Ctx, path: []const u8) !*File {
    const f: *File = try allocator.create(File);
    errdefer allocator.destroy(f);

    const full_source_path = try std.fs.path.join(allocator, &[_][]const u8{ ctx.cwd, path });
    defer allocator.free(full_source_path);

    std.debug.print("file path {s}\n", .{full_source_path});

    f.* = .{
        .path = path,
        .ctx = ctx,
    };
    return f;
}

pub fn deinit(self: *File, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

const std = @import("std");
const Compiler = @import("Compiler.zig");
