scenes: *scenes,
nav: ui.nav,
allocator: std.mem.Allocator,
config: *config,
world: *c.ecs_world_t,

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
    const world = ecs.init();
    errdefer ecs.deinit(world);
    const d = scenes.init(allocator, cfg, world);
    errdefer d.deinit();

    app = allocator.create(App) catch @panic("OOM");
    app.* = .{
        .scenes = d,
        .allocator = allocator,
        .nav = ui.nav.init(d),
        .config = cfg,
        .world = world,
    };
    return app;
}

pub fn deinit(self: *App) void {
    self.scenes.deinit();
    ecs.deinit(self.world);
    rhi.deinit();
    ui.deinit();
    self.config.deinit();
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
const c = @import("c.zig").c;
const ui = @import("ui/ui.zig");
const scenes = @import("scenes/scenes.zig");
const rhi = @import("rhi/rhi.zig");
const config = @import("config/config.zig");
const ecs = @import("ecs/ecs.zig");
