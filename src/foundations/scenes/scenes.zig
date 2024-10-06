scene_instance: ?ui.ui_state.scenes = null,
next_scene_type: ?ui.ui_state.scene_type = null,
context: SceneContext,

allocator: std.mem.Allocator,

const Scenes = @This();

pub const SceneContext = struct {
    cfg: *const config,
    args: Args,
    textures_loader: *assets.loader.Loader(assets.Image),
    obj_loader: *assets.loader.Loader(assets.Obj),
};

pub fn init(allocator: std.mem.Allocator, ctx: SceneContext) *Scenes {
    const scenes = allocator.create(Scenes) catch @panic("OOM");
    errdefer allocator.destroy(scenes);
    scenes.* = .{
        .allocator = allocator,
        .context = ctx,
    };
    scenes.initScene(ui.ui_state.scene_type.six_textured_torus);
    return scenes;
}

pub fn deinit(self: *Scenes) void {
    self.deinitScene();
    self.allocator.destroy(self);
}

pub fn setScene(self: *Scenes, dt: ui.ui_state.scene_type) void {
    self.next_scene_type = dt;
}

fn updateSceneType(self: *Scenes) void {
    const dt = self.next_scene_type orelse return;
    self.next_scene_type = null;
    if (self.scene_instance) |cdt| if (cdt == dt) return;
    ui.showCursor();
    self.deinitScene();
    self.initScene(dt);
}

fn initScene(self: *Scenes, dt: ui.ui_state.scene_type) void {
    @setEvalBranchQuota(10_000);
    self.scene_instance = switch (dt) {
        inline else => |dtag| @unionInit(ui.ui_state.scenes, @tagName(dtag), std.meta.Child(
            std.meta.TagPayload(
                ui.ui_state.scenes,
                dtag,
            ),
        ).init(self.allocator, self.context)),
    };
}

fn deinitScene(self: Scenes) void {
    if (self.scene_instance) |di| {
        switch (di) {
            inline else => |d| d.deinit(self.allocator),
        }
    }
}

pub fn updateScene(self: *Scenes, _: f64) void {
    self.updateSceneType();
}

pub fn drawScene(self: Scenes, frame_time: f64) void {
    if (self.scene_instance) |di| {
        switch (di) {
            inline else => |d| d.draw(frame_time),
        }
    }
}

const std = @import("std");
const ui = @import("../ui/ui.zig");
const config = @import("../config/config.zig");
const Args = @import("../Args.zig");

pub const cgpoc = @import("cgpoc/cgpoc.zig");
pub const graphics = @import("graphics/graphics.zig");
pub const math = @import("math/math.zig");
pub const shapes = @import("shapes/shapes.zig");
pub const assets = @import("../assets/assets.zig");
