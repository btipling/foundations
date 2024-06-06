pub fn main() !void {
    std.debug.print("Hello Foundations!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const a = app.init(gpa.allocator());
    defer a.deinit();

    a.run();

    std.debug.print("Goodbye Foundations!\n", .{});
}

const std = @import("std");
const app = @import("foundations/app.zig");
