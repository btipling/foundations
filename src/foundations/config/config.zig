fullscreen: bool = false,
maximized: bool = false,
decorated: bool = true,
width: u32 = 0,
height: u32 = 0,
allocator: std.mem.Allocator,

const Config = @This();

pub fn open(self: Config) void {
    const config_bytes = config_file.read(self.allocator);
    if (config_bytes) |b| {
        defer self.allocator.free(b);
        std.debug.print("config bytes len {d}\n", .{b.len});
    } else {
        std.debug.print("no config\n", .{});
    }
    config_file.write(self.allocator, "lol");
}

pub fn save(self: Config) void {
    const config_bytes = config_file.read(self.allocator);
    if (config_bytes) |b| {
        defer self.allocator.free(b);
        std.debug.print("config bytes len {d}\n", .{b.len});
    } else {
        std.debug.print("no config\n", .{});
    }
    config_file.write(self.allocator, "lol");
}

const std = @import("std");
const config_file = @import("config_file.zig");
pub const parser = @import("config_parser.zig");
