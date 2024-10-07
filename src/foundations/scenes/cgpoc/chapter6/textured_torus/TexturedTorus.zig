allocator: std.mem.Allocator,
torus: object.object = .{ .norender = .{} },
cubemap: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*TexturedTorus, physics.Integrator(physics.SmoothDeceleration)),
brick_texture: ?rhi.Texture = null,
cubemap_texture: ?rhi.Texture = null,
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,

const TexturedTorus = @This();

const vertex_shader: []const u8 = @embedFile("../../../../shaders/i_obj_vert.glsl");
const cube_map_vert: []const u8 = @embedFile("../../../../shaders/cube_map_vert.glsl");

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
    pd.renderDebugCross();
    pd.renderCubemap();
    pd.renderTorus();
    return pd;
}

pub fn deinit(self: *TexturedTorus, allocator: std.mem.Allocator) void {
    if (self.brick_texture) |et| {
        et.deinit();
    }
    self.cross.deinit(allocator);
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
        c.glDisable(c.GL_DEPTH_TEST);
        c.glFrontFace(c.GL_CCW);
        rhi.drawObjects(objects[0..]);
        c.glFrontFace(c.GL_CW);
        c.glEnable(c.GL_DEPTH_TEST);
    }
    self.cross.draw(dt);
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

pub fn renderDebugCross(self: *TexturedTorus) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.identity(),
        5,
    );
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
        s.attach(self.allocator, rhi.Shader.single_vertex(cube_map_vert)[0..]);
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
    var parallelepiped: object.object = .{
        .parallelepiped = object.Parallelepiped.initCubemap(
            prog,
            i_datas[0..],
            false,
        ),
    };
    parallelepiped.parallelepiped.mesh.linear_colorspace = false;
    // "C:\Users\swart\AppData\Local\foundations_game_engine\textures\cgpoc\cubemaps\AlienWorld\alienWorldSkyBox.jpg"
    // if (self.cubemap_texture) |*bt| {
    //     bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\cubemaps\\LakeIslands\\lakeIslandSkyBox.jpg") catch null, prog, "f_samp") catch {
    //         self.brick_texture = null;
    //     };
    // }
    if (self.cubemap_texture) |*bt| {
        if (true) {
            bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\cubemaps\\AlienWorld\\alienWorldSkyBox.jpg") catch null, prog, "f_samp") catch {
                self.brick_texture = null;
            };
        } else {
            var cm: assets.Cubemap = .{
                .path = "cgpoc\\cubemaps\\AlienWorld\\cubeMap",
                .textures_loader = self.ctx.textures_loader,
            };
            cm.names[0] = "xp.tif";
            cm.names[1] = "xn.tif";
            cm.names[2] = "yp.tif";
            cm.names[3] = "yn.tif";
            cm.names[4] = "zp.tif";
            cm.names[5] = "zn.tif";
            var images: ?[6]*assets.Image = null;
            if (cm.loadAll(self.allocator)) {
                images = cm.images;
            } else |_| {}
            bt.setupCubemap(images, prog, "f_cubesamp") catch {
                self.brick_texture = null;
            };
        }
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
const assets = @import("../../../../assets/assets.zig");
