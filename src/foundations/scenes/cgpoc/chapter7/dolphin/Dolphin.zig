allocator: std.mem.Allocator,
dolphin: object.object = .{ .norender = .{} },
parallelepiped: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*Dolphin, physics.Integrator(physics.SmoothDeceleration)),
dolphin_texture: ?rhi.Texture = null,
ground_texture: ?rhi.Texture = null,
shadowmap_program: u32 = 0,
shadow_mvp: math.matrix,
shadow_texture: ?rhi.Texture = null,
shadow_uniform: rhi.Uniform = undefined,
shadow_x_up: rhi.Uniform = undefined,
shadow_framebuffer: rhi.Framebuffer = undefined,
ctx: scenes.SceneContext,
materials: rhi.Buffer,
lights: rhi.Buffer,

const Dolphin = @This();

const vertex_shader: []const u8 = @embedFile("blinn_phong_vert.glsl");
const shadow_vertex_shader: []const u8 = @embedFile("../../../../shaders/shadow_vert.glsl");
const frag_shader: []const u8 = @embedFile("blinn_phong_frag.glsl");
const matte_frag_shader: []const u8 = @embedFile("blinn_phong_frag_matte.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Dolphin",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Dolphin {
    const pd = allocator.create(Dolphin) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*Dolphin, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pd,
        integrator,
        .{ 0, 2, -3 },
        std.math.pi - std.math.pi / 4.0,
    );
    errdefer cam.deinit(allocator);
    cam.updateGlobalAmbient(.{ 0.01, 0.01, 0.01, 1.0 });

    const mats = [_]lighting.Material{
        .{
            .ambient = [4]f32{ 0.2, 0.2, 0.2, 1.0 },
            .diffuse = [4]f32{ 0.8, 0.8, 0.8, 1.0 },
            .specular = [4]f32{ 0.25, 0.25, 0.25, 1.0 },
            .shininess = 32.0,
        },
    };

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const light_position: math.vector.vec3 = .{ 10, 5, -9 };
    const light_dir: math.vector.vec3 = math.vector.normalize(light_position);
    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.5, 0.5, 0.5, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = .{ light_dir[0], light_dir[1], light_dir[2], 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .direction,
        },
    };
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld);
    errdefer lights_buf.deinit();

    // Shadow objects
    const shadow_mvp = generateShadowMatrix(light_position, light_dir, ctx);

    const shadowmap_program = rhi.createProgram();
    errdefer c.glDeleteProgram(shadowmap_program);

    {
        var s: rhi.Shader = .{
            .program = shadowmap_program,
            .instance_data = true,
            .fragment_shader = .shadow,
        };
        s.attach(allocator, rhi.Shader.single_vertex(shadow_vertex_shader)[0..]);
    }

    var shadow_uniform: rhi.Uniform = rhi.Uniform.init(shadowmap_program, "f_shadow_m");
    shadow_uniform.setUniformMatrix(shadow_mvp);
    var shadow_xup: rhi.Uniform = rhi.Uniform.init(shadowmap_program, "f_xup_shadow");
    shadow_xup.setUniformMatrix(shadow_mvp);

    var shadow_texture = rhi.Texture.init(ctx.args.disable_bindless) catch @panic("unable to create shadow texture");
    errdefer shadow_texture.deinit();
    shadow_texture.setupShadow(
        shadowmap_program,
        "f_shadow_texture",
        ctx.cfg.fb_width,
        ctx.cfg.fb_height,
    ) catch @panic("unable to setup shadow texture");

    var shadow_framebuffer = rhi.Framebuffer.init();
    errdefer shadow_framebuffer.deinit();
    shadow_framebuffer.setupForShadowMap(shadow_texture) catch @panic("unable to setup shadow map framebuffer");

    pd.* = .{
        .allocator = allocator,
        .view_camera = cam,
        .ctx = ctx,
        .materials = mats_buf,
        .lights = lights_buf,
        .shadowmap_program = shadowmap_program,
        .shadow_framebuffer = shadow_framebuffer,
        .shadow_texture = shadow_texture,
        .shadow_mvp = shadow_mvp,
        .shadow_uniform = shadow_uniform,
        .shadow_x_up = shadow_xup,
    };

    pd.renderParallepiped();
    errdefer pd.deleteParallepiped();

    pd.renderDolphin();
    errdefer pd.deleteDolphin();

    return pd;
}

pub fn deinit(self: *Dolphin, allocator: std.mem.Allocator) void {
    self.deleteParallepiped();
    self.deleteDolphin();
    if (self.shadow_texture) |t| {
        t.deinit();
    }
    if (self.ground_texture) |gt| {
        gt.deinit();
    }
    if (self.dolphin_texture) |dt| {
        dt.deinit();
    }
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    self.materials.deinit();
    self.materials = undefined;
    self.lights.deinit();
    self.lights = undefined;
    allocator.destroy(self);
}

fn generateShadowMatrix(light_pos: math.vector.vec3, light_dir: math.vector.vec3, ctx: scenes.SceneContext) math.matrix {
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translate(light_pos[0], light_pos[1], light_pos[2]));
    const a1: math.rotation.AxisAngle = .{
        .angle = math.vector.angleBetweenVectors(physics.camera.world_right, light_dir),
        .axis = physics.camera.world_right,
    };
    var q1 = math.rotation.axisAngleToQuat(a1);
    q1 = math.vector.normalize(q1);
    const a2: math.rotation.AxisAngle = .{
        .angle = math.vector.angleBetweenVectors(physics.camera.world_up, light_dir),
        .axis = physics.camera.world_up,
    };
    var q2 = math.rotation.axisAngleToQuat(a2);
    q2 = math.vector.normalize(q2);
    const q = math.rotation.multiplyQuaternions(q1, q2);
    m = math.matrix.transformMatrix(m, math.matrix.normalizedQuaternionToMatrix(q));
    m = math.matrix.cameraInverse(m);
    // const P = math.matrix.orthographicProjection(0, 9, 0, 6, ctx.cfg.near, ctx.cfg.far);

    const s = @as(f32, @floatFromInt(ctx.cfg.width)) / @as(f32, @floatFromInt(ctx.cfg.height));
    const g: f32 = 1.0 / @tan(ctx.cfg.fovy * 0.5);
    var P = math.matrix.perspectiveProjectionCamera(g, s, 0.01, 750);
    P = math.matrix.transformMatrix(P, math.matrix.leftHandedXUpToNDC());
    m = math.matrix.transformMatrix(P, m);
    return m;
}

pub fn draw(self: *Dolphin, dt: f64) void {
    self.genShadowMap();
    self.view_camera.update(dt);
    if (self.ground_texture) |gt| {
        gt.bind();
    }
    if (self.dolphin_texture) |t| {
        t.bind();
    }
    if (self.shadow_texture) |t| {
        t.bind();
    }
    {
        const objects: [1]object.object = .{
            self.parallelepiped,
        };
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{
            self.dolphin,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn genShadowMap(self: *Dolphin) void {
    c.glEnable(c.GL_DEPTH_TEST);
    c.glClear(c.GL_DEPTH_BUFFER_BIT);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_LEQUAL);

    c.glEnable(c.GL_POLYGON_OFFSET_FILL);
    c.glPolygonOffset(2.0, 4.0);
    self.shadow_framebuffer.bind();
    self.shadow_framebuffer.attachDepthTexture(self.shadow_texture.?);
    self.shadow_x_up.setUniformMatrix(math.matrix.identity());
    {
        var o = self.parallelepiped;
        o.parallelepiped.mesh.gen_shadowmap = true;
        const objects: [1]object.object = .{o};
        rhi.drawObjects(objects[0..]);
    }
    self.shadow_x_up.setUniformMatrix(math.matrix.transpose(math.matrix.mc(.{
        0, 0, -1, 0,
        1, 0, 0,  0,
        0, 1, 0,  0,
        0, 0, 0,  1,
    })));
    {
        var o = self.dolphin;
        o.obj.mesh.gen_shadowmap = true;
        const objects: [1]object.object = .{o};
        rhi.drawObjects(objects[0..]);
    }
    self.shadow_framebuffer.unbind();
    c.glDisable(c.GL_POLYGON_OFFSET_FILL);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glClear(c.GL_DEPTH_BUFFER_BIT);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_LEQUAL);
}

pub fn updateCamera(_: *Dolphin) void {}

pub fn deleteDolphin(self: *Dolphin) void {
    const objects: [1]object.object = .{
        self.dolphin,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderDolphin(self: *Dolphin) void {
    var dolphin_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\Dolphin\\dolphinHighPoly.obj") catch null) |o| {
        dolphin_model = o;
    } else {
        return;
    }

    const prog = rhi.createProgram();
    self.dolphin_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .xup = .wavefront,
            .lighting = .blinn_phong,
            .frag_body = frag_shader,
            .fragment_shader = rhi.Texture.frag_shader(self.dolphin_texture),
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
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
    if (self.dolphin_texture) |*bt| {
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\Dolphin\\Dolphin_HighPolyUV.png") catch null, prog, "f_samp") catch {
            self.dolphin_texture = null;
        };
    }
    var dolphin_object: object.object = dolphin_model.toObject(prog, i_datas[0..]);
    dolphin_object.obj.mesh.shadowmap_program = self.shadowmap_program;
    var u: rhi.Uniform = rhi.Uniform.init(prog, "f_shadow_m");
    self.shadow_texture.?.addUniform(prog, "f_shadow_texture");
    u.setUniformMatrix(math.matrix.transformMatrix(math.matrix.transpose(math.matrix.mc(.{
        0.5, 0.0, 0.0, 0.0,
        0.0, 0.5, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.5, 0.5, 0.0, 1.0,
    })), self.shadow_mvp));
    self.dolphin = dolphin_object;
}

pub fn deleteParallepiped(self: *Dolphin) void {
    const objects: [1]object.object = .{
        self.dolphin,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderParallepiped(self: *Dolphin) void {
    const prog = rhi.createProgram();
    self.ground_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .lighting = .blinn_phong,
            .frag_body = matte_frag_shader,
            .fragment_shader = rhi.Texture.frag_shader(self.ground_texture),
            .shadowmaps = true,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(-11, -5, -5));
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(10));
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
        .parallelepiped = object.Parallelepiped.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    parallelepiped.parallelepiped.mesh.linear_colorspace = false;
    parallelepiped.parallelepiped.mesh.shadowmap_program = self.shadowmap_program;
    if (self.ground_texture) |*bt| {
        bt.setup(self.ctx.textures_loader.loadAsset("cgpoc\\luna\\grass.jpg") catch null, prog, "f_samp_1") catch {
            self.ground_texture = null;
        };
        bt.texture_unit = 1;
        self.ground_texture = bt.*;
    }
    var u: rhi.Uniform = rhi.Uniform.init(prog, "f_shadow_m");
    self.shadow_texture.?.addUniform(prog, "f_shadow_texture");
    u.setUniformMatrix(math.matrix.transformMatrix(math.matrix.transpose(math.matrix.mc(.{
        0.5, 0.0, 0.0, 0.0,
        0.0, 0.5, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.5, 0.5, 0.0, 1.0,
    })), self.shadow_mvp));
    self.parallelepiped = parallelepiped;
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
const lighting = @import("../../../../lighting/lighting.zig");
