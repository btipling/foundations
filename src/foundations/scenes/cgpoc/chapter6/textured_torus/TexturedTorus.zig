allocator: std.mem.Allocator,
torus: object.object = .{ .norender = .{} },
cubemap: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*TexturedTorus, physics.Integrator(physics.SmoothDeceleration)),
brick_texture: ?rhi.Texture = null,
cubemap_texture: ?rhi.Texture = null,
ctx: scenes.SceneContext,

const TexturedTorus = @This();

const vertex_shader: []const u8 = @embedFile("../../../../shaders/i_obj_vert.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Textured Torus",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *TexturedTorus {
    const pd = allocator.create(TexturedTorus) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*TexturedTorus, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pd,
        integrator,
        .{ 0, 0, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    pd.* = .{
        .allocator = allocator,
        .view_camera = cam,
        .ctx = ctx,
    };
    pd.renderCubemap();
    pd.renderTorus();
    return pd;
}

pub fn deinit(self: *TexturedTorus, allocator: std.mem.Allocator) void {
    if (self.brick_texture) |et| {
        et.deinit();
    }
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *TexturedTorus, dt: f64) void {
    self.view_camera.update(dt);
    if (self.brick_texture) |t| {
        t.bind();
    }
    if (self.cubemap_texture) |t| {
        t.bind();
    }
    {
        const objects: [1]object.object = .{
            self.cubemap,
        };
        c.glFrontFace(c.GL_CCW);
        rhi.drawObjects(objects[0..]);
        c.glFrontFace(c.GL_CW);
    }
    {
        const objects: [1]object.object = .{
            self.torus,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn updateCamera(_: *TexturedTorus) void {}

pub fn renderTorus(self: *TexturedTorus) void {
    const prog = rhi.createProgram();
    self.brick_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = rhi.Texture.frag_shader(self.brick_texture),
        };
        const partials = [_][]const u8{vertex_shader};
        s.attach(self.allocator, @ptrCast(partials[0..]));
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(0, -5, -5));
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
    const torus: object.object = .{
        .torus = object.Torus.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    if (self.brick_texture) |*bt| {
        bt.wrap_s = c.GL_REPEAT;
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\luna\\brick1.jpg") catch null, prog, "f_samp") catch {
            self.brick_texture = null;
        };
    }
    self.torus = torus;
}

pub fn updateCubemapTransform(_: *TexturedTorus, prog: u32) void {
    const m = math.matrix.translate(0, 0, 0);
    rhi.setUniformMatrix(prog, "f_cube_transform", m);
}

pub fn renderCubemap(self: *TexturedTorus) void {
    const prog = rhi.createProgram();
    self.cubemap_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = rhi.Texture.frag_shader(self.cubemap_texture),
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(20));
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(-0.5, -0.5, -0.5));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 0, 1 },
        };
        i_datas[0] = i_data;
    }
    const parallelepiped: object.object = .{
        .parallelepiped = object.Parallelepiped.initCubemap(
            prog,
            i_datas[0..],
            false,
        ),
    };
    if (self.cubemap_texture) |*bt| {
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\cubemaps\\LakeIslands\\lakeIslandSkyBox.jpg") catch null, prog, "f_samp") catch {
            self.brick_texture = null;
        };
    }
    self.updateCubemapTransform(prog);
    self.cubemap = parallelepiped;
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
