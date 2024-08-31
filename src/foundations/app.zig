app_scenes: *scenes,
nav: ui.nav,
allocator: std.mem.Allocator,
app_config: *config,

const App = @This();

var app: *App = undefined;

pub fn init(allocator: std.mem.Allocator) *App {
    const glsl_version: []const u8 = "#version 460";

    const cfg = config.init(allocator);
    errdefer cfg.deinit();
    cfg.open();
    cfg.print();

    ui.init(allocator, cfg, glsl_version);
    errdefer ui.deinit();
    rhi.init(allocator);
    errdefer rhi.deinit();
    const app_scenes = scenes.init(allocator, cfg);
    errdefer app_scenes.deinit();

    app = allocator.create(App) catch @panic("OOM");
    app.* = .{
        .app_scenes = app_scenes,
        .allocator = allocator,
        .nav = ui.nav.init(app_scenes),
        .app_config = cfg,
    };
    return app;
}

pub fn deinit(self: *App) void {
    self.app_scenes.deinit();
    rhi.deinit();
    ui.deinit();
    self.app_config.deinit();
    self.allocator.destroy(self);
}

pub fn run(self: *App) void {
    while (!ui.shouldClose()) {
        rhi.beginFrame();
        ui.beginFrame();
        self.app_scenes.updateScene(ui.glfw.getTime());
        self.app_scenes.drawScene(ui.glfw.getTime());
        self.nav.draw();
        ui.endFrame();
    }
}

const std = @import("std");
const ui = @import("ui/ui.zig");
const scenes = @import("scenes/scenes.zig");
const rhi = @import("rhi/rhi.zig");
const config = @import("config/config.zig");
