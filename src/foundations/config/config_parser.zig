allocator: std.mem.Allocator,
bytes: []const u8,
map: std.StringArrayHashMapUnmanaged([]const u8) = .{},

const min_token_length = 5;
const parts_len_requirement = 2;
const token_separator = '=';

const Parser = @This();

pub fn init(allocator: std.mem.Allocator, bytes: []const u8) *Parser {
    const p: *Parser = allocator.create(Parser) catch @panic("OOM");
    p.* = .{
        .allocator = allocator,
        .bytes = bytes,
    };
    return p;
}

pub fn deinit(self: *Parser) void {
    self.map.deinit(self.allocator);
    self.map = undefined;
    self.allocator.destroy(self);
}

pub fn parse(self: *Parser) void {
    var it = std.mem.tokenizeSequence(u8, self.bytes, ";\n");
    while (it.next()) |tk| self.token(tk);
}

fn token(self: *Parser, e: []const u8) void {
    if (e.len < min_token_length) return;
    const b = std.mem.trim(u8, e, " \t\n");
    var it = std.mem.splitScalar(u8, b, token_separator);
    const key = it.first();
    const value = it.rest();
    if (key.len < parts_len_requirement) return;
    if (value.len < parts_len_requirement) return;
    self.map.put(self.allocator, key, value) catch @panic("OOM");
}

test parse {
    var tp = init(std.testing.allocator, "foo=bar;\nanimal=frog;\n");
    defer tp.deinit();
    tp.parse();
    try std.testing.expect(std.mem.eql(u8, "bar", tp.map.get("foo").?));
    try std.testing.expect(std.mem.eql(u8, "frog", tp.map.get("animal").?));
}

const std = @import("std");
