view_camera: *physics.camera.Camera(*Fog, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

materials: rhi.Buffer,
lights: rhi.Buffer,

const Fog = @This();

const mats = [_]lighting.Material{
    lighting.materials.Gold,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Torus Geometry",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Fog {
    const fog = allocator.create(Fog) catch @panic("OOM");
    errdefer allocator.destroy(fog);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*Fog, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        fog,
        integrator,
        .{ 2, -10, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ 0.5, -1.0, -0.3, 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        },
    };
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld);
    errdefer lights_buf.deinit();

    fog.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    fog.renderDebugCross();
    errdefer fog.deleteCross();

    return fog;
}

pub fn deinit(self: *Fog, allocator: std.mem.Allocator) void {
    self.deleteCross();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *Fog) void {}

pub fn draw(self: *Fog, dt: f64) void {
    self.view_camera.update(dt);
    self.cross.draw(dt);
}

pub fn deleteCross(self: *Fog) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *Fog) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, -0.025, -0.025),
        5,
    );
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const rhi = @import("../../../../rhi/rhi.zig");
const ui = @import("../../../../ui/ui.zig");
const scenes = @import("../../../scenes.zig");
const math = @import("../../../../math/math.zig");
const physics = @import("../../../../physics/physics.zig");
const scenery = @import("../../../../scenery/scenery.zig");
const Compiler = @import("../../../../../compiler/Compiler.zig");
const object = @import("../../../../object/object.zig");
const lighting = @import("../../../../lighting/lighting.zig");
