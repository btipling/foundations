app_scenes: *scenes,
nav: ui.nav,
allocator: std.mem.Allocator,
app_config: *config,
textures_loader: *assets.loader.Loader(assets.Image),
textures_3d_loader: *assets.loader.Loader(assets.Texture3D),
obj_loader: *assets.loader.Loader(assets.Obj),

const App = @This();

var app: *App = undefined;

pub fn init(allocator: std.mem.Allocator) *App {
    const glsl_version: []const u8 = "#version 460";

    const args = Args.init(allocator);

    const cfg = config.init(allocator);
    errdefer cfg.deinit();
    cfg.open();
    cfg.print();

    ui.init(allocator, cfg, glsl_version);
    errdefer ui.deinit();

    rhi.init(allocator);
    errdefer rhi.deinit();

    const textures_loader: *assets.loader.Loader(assets.Image) = assets.loader.Loader(assets.Image).init(
        allocator,
        "textures",
    );
    errdefer textures_loader.deinit();

    const textures_3d_loader: *assets.loader.Loader(assets.Texture3D) = assets.loader.Loader(assets.Texture3D).init(
        allocator,
        "textures_3d",
    );
    errdefer textures_loader.deinit();

    const obj_loader: *assets.loader.Loader(assets.Obj) = assets.loader.Loader(assets.Obj).init(
        allocator,
        "models",
    );
    errdefer obj_loader.deinit();

    const scene_ctx: scenes.SceneContext = .{
        .cfg = cfg,
        .args = args,
        .textures_loader = textures_loader,
        .textures_3d_loader = textures_3d_loader,
        .obj_loader = obj_loader,
    };
    const app_scenes = scenes.init(allocator, scene_ctx);
    errdefer app_scenes.deinit();

    app = allocator.create(App) catch @panic("OOM");
    app.* = .{
        .app_scenes = app_scenes,
        .allocator = allocator,
        .nav = ui.nav.init(app_scenes),
        .app_config = cfg,
        .textures_loader = textures_loader,
        .textures_3d_loader = textures_3d_loader,
        .obj_loader = obj_loader,
    };
    return app;
}

pub fn deinit(self: *App) void {
    self.app_scenes.deinit();
    self.obj_loader.deinit();
    self.textures_loader.deinit();
    self.textures_3d_loader.deinit();
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
const Args = @import("Args.zig");
const assets = @import("assets/assets.zig");
