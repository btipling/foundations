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

    _ = c.gladLoadGL(c.glfwGetProcAddress);

    while (!ui.shouldClose()) {
        c.glViewport(0, 0, @intCast(width), @intCast(height));
        rhi.clear();
        ui.beginFrame();
        ui.hellWorld();
        ui.endFrame();
    }

    std.debug.print("Exiting!\n", .{});
}

test "test stub" {
    try std.testing.expect(true);
}

const c = @cImport({
    @cInclude("glad/gl.h");
    @cInclude("GLFW/glfw3.h");
});

const std = @import("std");
const rhi = @import("rhi/rhi.zig");
const ui = @import("ui/ui.zig");
