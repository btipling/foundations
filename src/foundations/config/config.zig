pub fn init(allocator: std.mem.Allocator) void {
    const config_bytes = config_file.read(allocator);
    if (config_bytes) |b| {
        defer allocator.free(b);
        std.debug.print("config bytes len {d}\n", .{b.len});
    } else {
        std.debug.print("no config\n", .{});
    }
    config_file.write(allocator, "lol");
}

const std = @import("std");
const config_file = @import("config_file.zig");
