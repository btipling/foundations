includes: [max_includes]Include = undefined,
num_includes: usize = 0,
file: *File,

const max_includes = 1000;

pub const Include = struct {
    path: []const u8 = undefined,
    line: usize = 0,
};

pub const IncludeIterator = struct {
    includes: [max_includes]Include = undefined,
    num_includes: usize = 0,
    current: usize = 0,
    pub fn next(self: *IncludeIterator) ?Include {
        if (self.current == self.num_includes) return null;
        const rv = self.includes[self.current];
        self.current += 1;
        return rv;
    }
    pub fn reset(self: *IncludeIterator) void {
        self.current = 0;
    }
};

const ParserError = error{
    NoFileError,
};

const include_prefix = "//#include \"";
const include_len = include_prefix.len;

const Parser = @This();

pub fn init(allocator: std.mem.Allocator, file: *File) !*Parser {
    const p: *Parser = try allocator.create(Parser);
    errdefer allocator.destroy(p);
    p.* = .{
        .file = file,
    };
    return p;
}

pub fn parse(self: *Parser, allocator: std.mem.Allocator) !void {
    const bytes = self.file.bytes orelse return ParserError.NoFileError;
    var linesIterator = std.mem.splitScalar(u8, bytes, '\n');
    var line_num: usize = 1; // Line numbers in files start at 1.
    while (linesIterator.next()) |line| {
        const l = std.mem.trim(u8, line, "\r\t ");
        if (l.len <= include_len) {
            line_num += 1;
            continue;
        }
        if (!std.mem.eql(u8, include_prefix, l[0..include_len])) {
            line_num += 1;
            continue;
        }
        const end = std.mem.indexOf(u8, l[include_len..], "\"") orelse {
            line_num += 1;
            continue;
        };
        self.includes[self.num_includes] = .{
            .path = try allocator.dupe(u8, l[include_len .. include_len + end]),
            .line = line_num,
        };
        self.num_includes += 1;
        line_num += 1;
    }
}

pub fn debug(self: *Parser) void {
    std.debug.print("Found {d} includes.\n", .{self.num_includes});
    for (0..self.num_includes) |i| {
        std.debug.print("\t{d}: {s}\n", .{ self.includes[i].line, self.includes[i].path });
    }
}

pub fn deinit(self: *Parser, allocator: std.mem.Allocator) void {
    for (0..self.num_includes) |i| allocator.free(self.includes[i].path);
    self.num_includes = 0;
    allocator.destroy(self);
}

pub fn iterator(self: *const Parser) IncludeIterator {
    return .{
        .includes = self.includes,
        .num_includes = self.num_includes,
    };
}

test parse {
    const allocator = std.testing.allocator;
    var file: File = .{
        .path = "src/compiler/test/source.glsl",
        .bytes = @embedFile("test/source.glsl"),
    };
    const f = &file;
    var p = try init(allocator, f);
    defer p.deinit(allocator);

    try p.parse(allocator);

    try std.testing.expect(p.num_includes == 3);
    try std.testing.expect(std.mem.eql(u8, "src/compiler/test/camera.glsl", p.includes[0].path));
    try std.testing.expectEqual(14, p.includes[0].line);
    try std.testing.expect(std.mem.eql(u8, "src/compiler/test/lights.glsl", p.includes[1].path));
    try std.testing.expectEqual(18, p.includes[1].line);
    try std.testing.expect(std.mem.eql(u8, "src/compiler/test/materials.glsl", p.includes[2].path));
    try std.testing.expectEqual(19, p.includes[2].line);
}

const std = @import("std");
const builtin = @import("builtin");
const File = @import("File.zig");
