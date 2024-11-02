view_camera: *physics.camera.Camera(*SimulatingWater, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,
ui_state: SimulatingWaterUI = .{},
ready: bool = false,
lock_flip: bool = false,

floor: object.object = .{ .norender = .{} },

surface_top: object.object = .{ .norender = .{} },

surface_bottom: object.object = .{ .norender = .{} },

skybox: object.object = .{ .norender = .{} },
skybox_tex: ?rhi.Texture = null,

under_water: [3]rhi.Uniform = undefined,
is_under_water: bool = false,

materials: rhi.Buffer,
lights: rhi.Buffer,

// Reflection stuff
reflection_tex: rhi.Texture = undefined,
reflection_fbo: rhi.Framebuffer = undefined,

refraction_tex: rhi.Texture = undefined,
refraction_fbo: rhi.Framebuffer = undefined,

const SimulatingWater = @This();

const mats = [_]lighting.Material{
    lighting.materials.Silver,
    lighting.materials.ClearWater,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Simulating Water",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *SimulatingWater {
    const sw = allocator.create(SimulatingWater) catch @panic("OOM");
    errdefer allocator.destroy(sw);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*SimulatingWater, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        sw,
        integrator,
        .{ 2, -5, 0 },
        -std.math.pi / 3.0,
    );
    errdefer cam.deinit(allocator);

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd, "materials");
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.01, 0.01, 0.01, 1.0 },
            .diffuse = [4]f32{ 0.5, 0.5, 0.5, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ 4.0, 2.0, -3.75, 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        },
    };
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld, "lights");
    errdefer lights_buf.deinit();

    sw.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    sw.setupReflection();
    errdefer sw.reflection_tex.deinit();
    errdefer sw.reflection_fbo.deinit();

    sw.setupRefraction();
    errdefer sw.refraction_tex.deinit();
    errdefer sw.refraction_fbo.deinit();

    sw.renderDebugCross();
    errdefer sw.deleteCross();

    sw.renderFloor();
    errdefer rhi.deleteObject(sw.floor);

    sw.renderSurfaceTop();
    errdefer rhi.deleteObject(sw.surface_top);

    sw.renderSurfaceBottom();
    errdefer rhi.deleteObject(sw.surface_bottom);

    sw.renderSkybox();
    errdefer rhi.deleteObject(sw.skybox);

    sw.ready = true;

    return sw;
}

pub fn deinit(self: *SimulatingWater, allocator: std.mem.Allocator) void {
    rhi.deleteObject(self.skybox);
    rhi.deleteObject(self.surface_top);
    rhi.deleteObject(self.surface_bottom);
    rhi.deleteObject(self.floor);
    self.reflection_tex.deinit();
    self.reflection_fbo.deinit();
    self.refraction_tex.deinit();
    self.refraction_fbo.deinit();
    self.deleteCross();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(self: *SimulatingWater) void {
    if (!self.ready) return;
    if (self.lock_flip) return;
    var is_underater = self.is_under_water;
    self.is_under_water = self.view_camera.camera_pos[0] < 0;
    if (is_underater != self.is_under_water) {
        self.updateUnderWater(self.is_under_water);
        is_underater = self.is_under_water;
    }
}

fn updateUnderWater(self: *SimulatingWater, is_under_water: bool) void {
    const v: usize = if (is_under_water) 1 else 0;
    for (self.under_water) |uw| {
        uw.setUniform1i(v);
    }
    if (is_under_water) {
        self.view_camera.global_ambient = .{ 0.0, 0.0, 0.0, 1.0 };
    } else {
        self.view_camera.global_ambient = .{ 0.7, 0.7, 0.7, 1.0 };
    }
}

pub fn draw(self: *SimulatingWater, dt: f64) void {
    if (self.ui_state.light_updated) {
        self.updateLights();
        self.ui_state.light_updated = false;
    }
    self.view_camera.update(dt);
    self.drawReflection(dt);
    self.drawRefraction(dt);
    self.drawScene(dt);
}

fn drawReflection(self: *SimulatingWater, _: f64) void {
    const camera_x: f32 = self.view_camera.camera_pos[0];
    if (!self.is_under_water) {
        self.lock_flip = true;
        self.view_camera.camera_pos[0] = -camera_x;
        self.view_camera.flipVerticalOrientation();
    } else {
        self.updateUnderWater(false);
    }
    self.reflection_fbo.bind();
    {
        if (self.skybox_tex) |t| {
            t.bind();
        }
        rhi.drawHorizon(self.skybox);
    }
    if (!self.is_under_water) {
        self.view_camera.camera_pos[0] = camera_x;
        self.view_camera.flipVerticalOrientation();
        self.lock_flip = false;
    } else {
        self.updateUnderWater(true);
    }
}

fn drawRefraction(self: *SimulatingWater, _: f64) void {
    self.refraction_fbo.bind();
    {
        rhi.drawObject(self.floor);
    }
    self.refraction_fbo.unbind();
}

fn drawScene(self: *SimulatingWater, dt: f64) void {
    {
        if (self.skybox_tex) |t| {
            t.bind();
        }
        rhi.drawHorizon(self.skybox);
    }
    self.reflection_tex.bind();
    self.refraction_tex.bind();
    {
        rhi.drawObject(self.surface_top);
    }
    {
        rhi.drawObject(self.surface_bottom);
    }
    {
        rhi.drawObject(self.floor);
    }
    self.cross.draw(dt);
    self.ui_state.draw();
}

fn setupReflection(self: *SimulatingWater) void {
    var render_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch @panic("unable to create reflection texture");
    errdefer render_texture.deinit();
    render_texture.setupRenderTexture(
        self.ctx.cfg.fb_width,
        self.ctx.cfg.fb_height,
        "reflection",
    ) catch @panic("unable to setup reflection render texture");
    render_texture.texture_unit = 2;
    self.reflection_tex = render_texture;

    var depth_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch @panic("unable to create reflection texture");
    errdefer render_texture.deinit();
    depth_texture.setupDepthTexture(
        self.ctx.cfg.fb_width,
        self.ctx.cfg.fb_height,
        "reflection",
    ) catch @panic("unable to setup reflection depth texture");

    var reflection_framebuffer = rhi.Framebuffer.init();
    errdefer reflection_framebuffer.deinit();

    reflection_framebuffer.setupForColorRendering(
        render_texture,
        depth_texture,
    ) catch @panic("unable to setup reflection framebuffer");
    self.reflection_fbo = reflection_framebuffer;
}

fn setupRefraction(self: *SimulatingWater) void {
    var render_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch @panic("unable to create refraction texture");
    errdefer render_texture.deinit();
    render_texture.setupRenderTexture(
        self.ctx.cfg.fb_width,
        self.ctx.cfg.fb_height,
        "refraction",
    ) catch @panic("unable to setup refraction render texture");
    render_texture.texture_unit = 3;
    self.refraction_tex = render_texture;

    var depth_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch @panic("unable to create refraction texture");
    errdefer render_texture.deinit();
    depth_texture.setupDepthTexture(
        self.ctx.cfg.fb_width,
        self.ctx.cfg.fb_height,
        "refraction",
    ) catch @panic("unable to setup refraction depth texture");

    var refraction_framebuffer = rhi.Framebuffer.init();
    errdefer refraction_framebuffer.deinit();

    refraction_framebuffer.setupForColorRendering(
        render_texture,
        depth_texture,
    ) catch @panic("unable to setup refraction framebuffer");
    self.refraction_fbo = refraction_framebuffer;
}

fn updateLights(self: *SimulatingWater) void {
    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.01, 0.01, 0.01, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = self.ui_state.light_direction,
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .direction,
        },
    };
    self.lights.deinit();
    const ld: rhi.Buffer.buffer_data = .{ .lights = lights[0..] };
    var lights_buf = rhi.Buffer.init(ld, "lights");
    errdefer lights_buf.deinit();
    self.lights = lights_buf;
}

fn deleteCross(self: *SimulatingWater) void {
    self.cross.deinit(self.allocator);
}

fn renderDebugCross(self: *SimulatingWater) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(1.0, 0.0, 0.0),
        5,
    );
}

fn renderFloor(self: *SimulatingWater) void {
    var grid_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\grid\\grid.obj") catch null) |o| {
        grid_model = o;
    } else {
        return;
    }
    const prog = rhi.createProgram("floor");

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("floor_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    const frag = Compiler.runWithBytes(self.allocator, @embedFile("floor_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..], "floor");
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translateVec(.{ -10.5, -500, -500 }));
    m = math.matrix.transformMatrix(m, math.matrix.scale(0.5, 1000, 1000));
    const i_datas = [_]rhi.instanceData{
        .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        },
    };

    var grid_obj: object.object = .{ .parallelepiped = object.Parallelepiped.init(prog, i_datas[0..], "floor") };
    grid_obj.parallelepiped.mesh.linear_colorspace = true;
    var uw = rhi.Uniform.init(prog, "f_underwater") catch @panic("no uniform");
    uw.setUniform1i(0);
    self.under_water[0] = uw;
    self.floor = grid_obj;
}

fn renderSurfaceTop(self: *SimulatingWater) void {
    var grid_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\grid\\grid.obj") catch null) |o| {
        grid_model = o;
    } else {
        return;
    }
    const prog = rhi.createProgram("surface_top");
    const frag_bindings = [_]usize{ 2, 3 };
    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("surface_top_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    var frag = Compiler.runWithBytes(self.allocator, @embedFile("surface_top_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);
    frag = if (!disable_bindless) frag else rhi.Shader.disableBindless(
        frag,
        frag_bindings[0..],
    ) catch @panic("bindless");

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..], "surface_top");
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translateVec(.{ 0, -500, -500 }));
    m = math.matrix.transformMatrix(m, math.matrix.scale(1, 1000, 1000));
    const i_datas = [_]rhi.instanceData{
        .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        },
    };
    self.reflection_tex.addUniform(prog, "f_reflection") catch @panic("no reflection texture");
    self.refraction_tex.addUniform(prog, "f_refraction") catch @panic("no refraction texture");

    var grid_obj: object.object = .{ .quad = object.Quad.initPlane(prog, i_datas[0..], "surface_top") };
    grid_obj.quad.mesh.linear_colorspace = false;
    self.surface_top = grid_obj;
}

fn renderSurfaceBottom(self: *SimulatingWater) void {
    var grid_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\grid\\grid.obj") catch null) |o| {
        grid_model = o;
    } else {
        return;
    }
    const prog = rhi.createProgram("surface_bottom");
    const frag_bindings = [_]usize{2};
    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("surface_bot_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    var frag = Compiler.runWithBytes(self.allocator, @embedFile("surface_bot_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);
    frag = if (!disable_bindless) frag else rhi.Shader.disableBindless(
        frag,
        frag_bindings[0..],
    ) catch @panic("bindless");

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..], "surface_bot");
    var m = math.matrix.identity();
    _ = &m;
    m = math.matrix.transformMatrix(m, math.matrix.translateVec(.{ 0, -500, -500 }));
    m = math.matrix.transformMatrix(m, math.matrix.scale(1, 1000, 1000));
    m = math.matrix.transformMatrix(m, math.matrix.rotationY(std.math.pi));
    m = math.matrix.transformMatrix(m, math.matrix.translateVec(.{ 0, 0, -1 }));
    const i_datas = [_]rhi.instanceData{
        .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        },
    };

    var grid_obj: object.object = .{ .quad = object.Quad.initPlane(prog, i_datas[0..], "surface_bot") };
    grid_obj.quad.mesh.linear_colorspace = false;
    self.surface_bottom = grid_obj;
    self.reflection_tex.addUniform(prog, "f_reflection") catch @panic("no reflection texture");
    var uw = rhi.Uniform.init(prog, "f_underwater") catch @panic("no uniform");
    uw.setUniform1i(0);
    self.under_water[1] = uw;
}

pub fn renderSkybox(self: *SimulatingWater) void {
    const prog = rhi.createProgram("skybox");
    self.skybox_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.skybox_tex.?.texture_unit = 16;

    const frag_bindings = [_]usize{16};
    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("skybox_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);
    var frag = Compiler.runWithBytes(self.allocator, @embedFile("skybox_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);
    frag = if (!disable_bindless) frag else rhi.Shader.disableBindless(
        frag,
        frag_bindings[0..],
    ) catch @panic("bindless");

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..], "skybox");
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
            "skybox",
        ),
    };
    parallelepiped.parallelepiped.mesh.linear_colorspace = false;
    if (self.skybox_tex) |*t| {
        var cm: assets.Cubemap = .{
            .path = "cgpoc\\cubemaps\\big_sky\\cubemap",
            .textures_loader = self.ctx.textures_loader,
        };
        cm.names[0] = "xp.jpg";
        cm.names[1] = "xn.jpg";
        cm.names[2] = "yp.jpg";
        cm.names[3] = "yn.jpg";
        cm.names[4] = "zp.jpg";
        cm.names[5] = "zn.jpg";
        var images: ?[6]*assets.Image = null;
        if (cm.loadAll(self.allocator)) {
            images = cm.images;
        } else |_| {
            std.debug.print("failed to load textures\n", .{});
        }
        t.setupCubemap(images, prog, "f_skybox", "big_sky") catch {
            self.skybox_tex = null;
        };
    }
    self.skybox = parallelepiped;
    var uw = rhi.Uniform.init(prog, "f_underwater") catch @panic("no uniform");
    uw.setUniform1i(0);
    self.under_water[2] = uw;
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const rhi = @import("../../../../rhi/rhi.zig");
const ui = @import("../../../../ui/ui.zig");
const scenes = @import("../../../scenes.zig");
const math = @import("../../../../math/math.zig");
const physics = @import("../../../../physics/physics.zig");
const scenery = @import("../../../../scenery/scenery.zig");
const Compiler = @import("../../../../../fssc/Compiler.zig");
const object = @import("../../../../object/object.zig");
const lighting = @import("../../../../lighting/lighting.zig");
const assets = @import("../../../../assets/assets.zig");
const rendering = @import("../../../../rendering/rendering.zig");
const SimulatingWaterUI = @import("SimulatingWaterUI.zig");
