allocator: std.mem.Allocator,
shuttle: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*Shuttle, physics.Integrator(physics.SmoothDeceleration)),
shuttle_texture: ?rhi.Texture,
ctx: scenes.SceneContext,

const Shuttle = @This();

const vertex_shader: []const u8 = @embedFile("../../../../shaders/i_obj_vert.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Shuttle",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Shuttle {
    const pd = allocator.create(Shuttle) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*Shuttle, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pd,
        integrator,
        .{ 0, -15, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    pd.* = .{
        .allocator = allocator,
        .view_camera = cam,
        .shuttle_texture = null,
        .ctx = ctx,
    };
    pd.renderShuttle();
    return pd;
}

pub fn deinit(self: *Shuttle, allocator: std.mem.Allocator) void {
    if (self.shuttle_texture) |et| {
        et.deinit();
    }
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *Shuttle, dt: f64) void {
    self.view_camera.update(dt);
    if (self.shuttle_texture) |et| {
        et.bind();
    }
    {
        const objects: [1]object.object = .{
            self.shuttle,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn updateCamera(_: *Shuttle) void {}

pub fn renderShuttle(self: *Shuttle) void {
    if (self.ctx.obj_loader.loadAsset("cgpoc\\NasaShuttle\\shuttle.obj") catch null) |_| {
        std.debug.print("got shuttle\n", .{});
    } else {
        std.debug.print("no shuttle\n", .{});
    }
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const object = @import("../../../../object/object.zig");
const scenes = @import("../../../scenes.zig");
const physics = @import("../../../../physics/physics.zig");
const scenery = @import("../../../../scenery/scenery.zig");
