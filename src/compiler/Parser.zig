includes: [max_includes][]const u8 = undefined,
num_includes: usize = 0,
file: *File,

const max_includes = 1000;

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
    while (linesIterator.next()) |line| {
        const l = std.mem.trim(u8, line, "\r\t ");
        if (l.len <= include_len) continue;
        if (!std.mem.eql(u8, include_prefix, l[0..include_len])) continue;
        const end = std.mem.indexOf(u8, l[include_len..], "\"") orelse continue;
        self.includes[self.num_includes] = try allocator.dupe(u8, l[include_len .. include_len + end]);
        self.num_includes += 1;
    }
}

pub fn debug(self: *Parser) void {
    std.debug.print("Found {d} includes.\n", .{self.num_includes});
    for (0..self.num_includes) |i| {
        std.debug.print("\t{s}\n", .{self.includes[i]});
    }
}

pub fn deinit(self: *Parser, allocator: std.mem.Allocator) void {
    for (0..self.num_includes) |i| allocator.free(self.includes[i]);
    self.num_includes = 0;
    allocator.destroy(self);
}

const std = @import("std");
const builtin = @import("builtin");
const File = @import("File.zig");
