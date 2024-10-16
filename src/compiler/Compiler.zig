allocator: std.mem.Allocator,

const Compiler = @This();

pub fn init(allocator: std.mem.Allocator) *Compiler {
    const c: *Compiler = allocator.create(Compiler) catch @panic("OOM");
    c.* = .{
        .allocator = allocator,
    };
    return c;
}

pub fn run(_: *Compiler) void {
    std.debug.print("hello compiler.\n", .{});
}

pub fn deinit(self: *Compiler) void {
    self.allocator.destroy(self);
}

const std = @import("std");
