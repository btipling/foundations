pub fn main() !void {
    std.debug.print("Starting up!\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = gpa.allocator();

    const width: u32 = 1920;
    const height: u32 = 1080;
    const glsl_version: []const u8 = "#version 460";

    ui.init(a, width, height, glsl_version);
    defer ui.deinit();

    while (!ui.shouldClose()) {
        rhi.beginFrame();
        ui.beginFrame();
        ui.hellWorld();
        ui.endFrame();
    }

    std.debug.print("Exiting!\n", .{});
}

const std = @import("std");
const rhi = @import("rhi/rhi.zig");
const ui = @import("ui/ui.zig");
