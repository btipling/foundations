parser: *const Parser,
source_file: *File, // not owned
output_file: *File, // owned
output_path: []const u8, // owned
included_files: std.StringHashMapUnmanaged(*File) = .{},

const Includer = @This();

const IncluderError = error{
    NoSourceFileError,
    NoIncludeError,
};

pub fn init(allocator: std.mem.Allocator, source_file: *File, ctx: Compiler.Ctx, parser: *const Parser) !*Includer {
    const inc: *Includer = try allocator.create(Includer);
    errdefer allocator.destroy(inc);

    const output_path = try std.fs.path.join(allocator, &[_][]const u8{ ctx.args.output_path, ctx.args.file_name });
    errdefer allocator.free(output_path);

    var output_file = try File.init(allocator, ctx, output_path);
    errdefer output_file.deinit(allocator);

    inc.* = .{
        .parser = parser,
        .source_file = source_file,
        .output_path = output_path,
        .output_file = output_file,
    };
    return inc;
}

pub fn deinit(self: *Includer, allocator: std.mem.Allocator) void {
    var it = self.included_files.iterator();
    while (it.next()) |f| {
        f.value_ptr.*.deinit(allocator);
    }
    self.included_files.deinit(allocator);
    self.included_files = undefined;
    self.output_file.deinit(allocator);
    allocator.free(self.output_path);
    allocator.destroy(self);
}

pub fn fetch(self: *Includer, allocator: std.mem.Allocator, ctx: Compiler.Ctx) !void {
    var it = self.parser.iterator();
    while (it.next()) |inc| {
        if (self.included_files.contains(inc.path)) continue;
        const f = try File.init(allocator, ctx, inc.path);
        errdefer f.deinit(allocator);
        try self.included_files.put(allocator, inc.path, f);
    }
}

pub fn include(self: *Includer, allocator: std.mem.Allocator) !void {
    const bytes = self.source_file.bytes orelse return IncluderError.NoSourceFileError;
    var linesIterator = std.mem.splitScalar(u8, bytes, '\n');
    var line_num: usize = 1; // Line numbers in files start at 1.

    var new_bytes: std.ArrayListUnmanaged([]const u8) = .{};
    errdefer new_bytes.deinit(allocator);

    var it = self.parser.iterator();
    while (linesIterator.next()) |line| {
        try new_bytes.append(allocator, line);
        while (it.next()) |inc| {
            if (inc.line == line_num) {
                const include_bytes = blk: {
                    if (self.included_files.get(inc.path)) |f| {
                        break :blk f.bytes orelse return IncluderError.NoIncludeError;
                    } else {
                        return IncluderError.NoIncludeError;
                    }
                };
                try new_bytes.append(allocator, include_bytes);
            }
        }
        it.reset();
        line_num += 1;
    }
    const parts = try new_bytes.toOwnedSlice(allocator);
    defer allocator.free(parts);
    self.output_file.bytes = try std.mem.join(allocator, "\n", parts);
}

pub fn debug(self: *Includer) void {
    if (self.output_file.bytes) |b| {
        std.debug.print("`{s}`\n", .{b});
    } else std.debug.print("no output bytes\n", .{});
}

test include {
    const allocator = std.testing.allocator;
    var args: Args = .{
        .output_path = "src/compiler/test/",
        .file_name = "output.glsl",
    };
    const ctx: Compiler.Ctx = .{
        .cwd = "C:\\Users\\swart\\projects\\foundations\\",
        .args = &args,
    };
    var file: File = .{
        .path = "src/compiler/test/source.glsl",
        .bytes = @embedFile("test/source.glsl"),
    };
    const f = &file;
    var p = try Parser.init(allocator, f);
    defer p.deinit(allocator);

    try p.parse(allocator);
    var inc = try init(allocator, f, ctx, p);

    try inc.included_files.put(allocator, "src/compiler/test/camera.glsl", @constCast(&(.{ .bytes = @embedFile("test/camera.glsl") })));
    try inc.included_files.put(allocator, "src/compiler/test/lights.glsl", @constCast(&(.{ .bytes = @embedFile("test/lights.glsl") })));
    try inc.included_files.put(allocator, "src/compiler/test/materials.glsl", @constCast(&(.{ .bytes = @embedFile("test/materials.glsl") })));

    try inc.include(allocator);

    const expected_output: []const u8 = @embedFile("test/expected_output.glsl");
    try std.testing.expect(
        std.mem.eql(
            u8,
            expected_output,
            inc.output_file.bytes.?,
        ),
    );

    inc.included_files.deinit(allocator);
    inc.included_files = undefined;
    inc.output_file.deinit(allocator);
    allocator.free(inc.output_path);
    allocator.destroy(inc);
}

const std = @import("std");
const builtin = @import("builtin");
const File = @import("File.zig");
const Parser = @import("Parser.zig");
const Compiler = @import("Compiler.zig");
const Args = @import("Args.zig");
