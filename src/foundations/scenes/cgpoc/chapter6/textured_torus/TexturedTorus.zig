allocator: std.mem.Allocator,
torus: object.object = .{ .norender = .{} },
cubemap: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*TexturedTorus, physics.Integrator(physics.SmoothDeceleration)),
cubemap_texture: ?rhi.Texture = null,
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,

const TexturedTorus = @This();

const vertex_shader: []const u8 = @embedFile("torus_vert.glsl");
const frag_shader: []const u8 = @embedFile("torus_frag.glsl");
const cubemap_vert: []const u8 = @embedFile("../../../../shaders/cubemap_vert.glsl");

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
        .{ 2, -3, 4 },
        -std.math.pi / 2.0,
    );
    errdefer cam.deinit(allocator);

    pd.* = .{
        .allocator = allocator,
        .view_camera = cam,
        .ctx = ctx,
    };

    pd.renderDebugCross();
    errdefer pd.deleteCross();

    pd.renderCubemap();
    errdefer pd.deleteCubemap();

    pd.renderTorus();
    errdefer pd.deleteTorus();

    return pd;
}

pub fn deinit(self: *TexturedTorus, allocator: std.mem.Allocator) void {
    self.deleteTorus();
    self.deleteCubemap();
    if (self.cubemap_texture) |t| {
        t.deinit();
    }
    self.deleteCross();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *TexturedTorus, dt: f64) void {
    self.view_camera.update(dt);
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

pub fn deleteTorus(self: *TexturedTorus) void {
    const objects: [1]object.object = .{
        self.torus,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderTorus(self: *TexturedTorus) void {
    const prog = rhi.createProgram("torus");
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = if (rhi.Texture.disableBindless(self.ctx.args.disable_bindless)) .texture else .bindless,
            .frag_body = frag_shader,
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
            "torus",
        ),
    };
    self.torus = torus;
    if (self.cubemap_texture == null) return;
    self.cubemap_texture.?.addUniform(prog, "f_cubemap") catch @panic("uniform failed");
}

pub fn deleteCross(self: *TexturedTorus) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *TexturedTorus) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.identity(),
        5,
    );
}

pub fn deleteCubemap(self: *TexturedTorus) void {
    const objects: [1]object.object = .{
        self.cubemap,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderCubemap(self: *TexturedTorus) void {
    const prog = rhi.createProgram("cubemap");
    self.cubemap_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .cubemap = true,
            .instance_data = true,
            .fragment_shader = .texture,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(cubemap_vert)[0..]);
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
            "cubemap",
        ),
    };
    parallelepiped.parallelepiped.mesh.linear_colorspace = false;
    if (self.cubemap_texture) |*bt| {
        var cm: assets.Cubemap = .{
            .path = "cgpoc\\cubemaps\\AlienWorld\\cubeMap",
            .textures_loader = self.ctx.textures_loader,
        };
        cm.names[0] = "xp.png";
        cm.names[1] = "xn.png";
        cm.names[2] = "yp.png";
        cm.names[3] = "yn.png";
        cm.names[4] = "zp.png";
        cm.names[5] = "zn.png";
        var images: ?[6]*assets.Image = null;
        if (cm.loadAll(self.allocator)) {
            images = cm.images;
        } else |_| {
            std.debug.print("failed to load textures\n", .{});
        }
        bt.setupCubemap(images, prog, "f_cubemap", "alien_world") catch {
            self.cubemap_texture = null;
        };
    }
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
