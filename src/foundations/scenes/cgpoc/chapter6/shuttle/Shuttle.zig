allocator: std.mem.Allocator,
shuttle: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*Shuttle, physics.Integrator(physics.SmoothDeceleration)),
shuttle_texture: ?rhi.Texture,
ctx: scenes.SceneContext,

const Shuttle = @This();

const vertex_shader: []const u8 = @embedFile("../../../../shaders/i_obj_wavefront_vert.glsl");

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
    var shuttle_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\NasaShuttle\\shuttle.obj") catch null) |o| {
        std.debug.print("got shuttle\n", .{});
        shuttle_model = o;
    } else {
        std.debug.print("no shuttle\n", .{});
        return;
    }

    const prog = rhi.createProgram();
    self.shuttle_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .xup = .wavefront,
            .fragment_shader = rhi.Texture.frag_shader(self.shuttle_texture),
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
    if (self.shuttle_texture) |*bt| {
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\NasaShuttle\\spstob_1.jpg") catch null, prog, "f_samp") catch {
            self.shuttle_texture = null;
        };
    }
    const shuttle_object: object.object = shuttle_model.toObject(prog, i_datas[0..]);
    self.view_camera.addProgram(prog);
    self.shuttle = shuttle_object;
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
const assets = @import("../../../../assets/assets.zig");
