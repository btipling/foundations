pub fn main() !void {
    std.debug.print("Starting ft3d.\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const g: *Generator = try Generator.init(gpa.allocator());
    defer g.deinit();

    try g.run();

    std.debug.print("ft3d finished.\n", .{});
}

const std = @import("std");
const Generator = @import("ft3d/Generator.zig");
