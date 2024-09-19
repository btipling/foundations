disable_bindless: bool = false,

const Args = @This();

pub fn init(allocator: std.mem.Allocator) Args {
    const arg_values = std.process.argsAlloc(allocator) catch @panic("OOM");
    defer std.process.argsFree(allocator, arg_values);
    var rv: Args = .{};
    for (arg_values) |av| {
        std.debug.print("{s}\n", .{av});
        if (std.mem.eql(u8, av, "--disable_bindless")) {
            rv.disable_bindless = true;
        }
        if (std.mem.eql(u8, av, "--help")) {
            std.debug.print("--disable_bindless to disable bindless textures\n", .{});
        }
    }
    std.debug.print("args.disable_bindless: {any}\n", .{rv.disable_bindless});
    return rv;
}

const std = @import("std");
