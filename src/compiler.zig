pub fn main() !void {
    std.debug.print("Starting compiler.\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const c: *Compiler = try Compiler.init(gpa.allocator());
    defer c.deinit();

    try c.run();

    std.debug.print("Compiler finished.\n", .{});
}

const std = @import("std");
const Compiler = @import("compiler/Compiler.zig");
