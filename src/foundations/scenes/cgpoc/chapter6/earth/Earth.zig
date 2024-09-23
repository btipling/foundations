allocator: std.mem.Allocator,
sphere: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*Earth, physics.Integrator(physics.SmoothDeceleration)),
earth_texture: ?rhi.Texture = null,
ctx: scenes.SceneContext,

const Earth = @This();

const vertex_shader: []const u8 = @embedFile("../../../../shaders/i_obj_vert.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Earth",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Earth {
    const pd = allocator.create(Earth) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*Earth, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pd,
        integrator,
        .{ 3, -15, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    pd.* = .{
        .allocator = allocator,
        .view_camera = cam,
        .ctx = ctx,
    };
    pd.renderSphere();
    return pd;
}

pub fn deinit(self: *Earth, allocator: std.mem.Allocator) void {
    if (self.earth_texture) |et| {
        et.deinit();
    }
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *Earth, dt: f64) void {
    self.view_camera.update(dt);
    if (self.earth_texture) |et| {
        et.bind();
    }
    {
        const objects: [1]object.object = .{
            self.sphere,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn updateCamera(_: *Earth) void {}

pub fn renderSphere(self: *Earth) void {
    const prog = rhi.createProgram();
    self.earth_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = rhi.Texture.frag_shader(self.earth_texture),
        };
        const partials = [_][]const u8{vertex_shader};
        s.attach(self.allocator, @ptrCast(partials[0..]));
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(0, -1, -1));
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(2));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    if (self.earth_texture) |*bt| {
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\earth.jpg") catch null, prog, "f_samp") catch {
            self.earth_texture = null;
        };
    }
    self.sphere = sphere;
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
