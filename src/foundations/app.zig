scenes: *scenes,
nav: ui.nav,
allocator: std.mem.Allocator,

const App = @This();

var app: *App = undefined;

pub fn init(allocator: std.mem.Allocator) *App {
    const width: u32 = 1080;
    const height: u32 = 1080;
    const glsl_version: []const u8 = "#version 460";

    ui.init(allocator, width, height, glsl_version);
    errdefer ui.deinit();
    rhi.init(allocator);
    errdefer rhi.deinit();
    const d = scenes.init(allocator);
    errdefer d.deinit();

    app = allocator.create(App) catch @panic("OOM");
    app.* = .{
        .scenes = d,
        .allocator = allocator,
        .nav = ui.nav.init(d),
    };
    return app;
}

pub fn deinit(self: *App) void {
    self.scenes.deinit();
    rhi.deinit();
    ui.deinit();
    self.allocator.destroy(self);
}

pub fn run(self: *App) void {
    while (!ui.shouldClose()) {
        rhi.beginFrame();
        ui.beginFrame();
        self.scenes.updateScene(ui.glfw.getTime());
        self.scenes.drawScene(ui.glfw.getTime());
        self.nav.draw();
        ui.endFrame();
    }
}

const std = @import("std");
const ui = @import("ui/ui.zig");
const scenes = @import("scenes/scenes.zig");
const rhi = @import("rhi/rhi.zig");
