view_camera: *physics.camera.Camera(*SurfaceDetail, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
allocator: std.mem.Allocator,
ui_state: SurfaceDetailUI,
materials: rhi.Buffer,
lights: rhi.Buffer,
moon: object.object = .{ .norender = .{} },
moon_normal_map: ?rhi.Texture = null,
moon_texture: ?rhi.Texture = null,
earth: object.object = .{ .norender = .{} },
earth_height_map: ?rhi.Texture = null,
earth_normal_map: ?rhi.Texture = null,
earth_texture: ?rhi.Texture = null,
cubemap: object.object = .{ .norender = .{} },
cubemap_texture: ?rhi.Texture = null,
cross: scenery.debug.Cross = undefined,
sphere: object.object = .{ .norender = .{} },
sphere_matrix: rhi.Uniform = undefined,
moon_light_pos: rhi.Uniform = undefined,
earth_light_pos: rhi.Uniform = undefined,

const SurfaceDetail = @This();

const mats = [_]lighting.Material{
    lighting.materials.Silver,
};

const moon_vertex_shader: []const u8 = @embedFile("moon_vert.glsl");
const moon_frag_shader: []const u8 = @embedFile("moon_frag.glsl");
const cubemap_vert: []const u8 = @embedFile("../../../../shaders/cubemap_vert.glsl");
const sphere_vertex_shader: []const u8 = @embedFile("sphere_vertex.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Surface Detail",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *SurfaceDetail {
    const sd = allocator.create(SurfaceDetail) catch @panic("OOM");
    errdefer allocator.destroy(sd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var max_texture_units: c.GLint = 0;
    c.glGetIntegerv(c.GL_MAX_TEXTURE_IMAGE_UNITS, &max_texture_units);
    if (max_texture_units < 17) {
        std.log.warn("not enough texture units: {d}, required: 17\n", .{max_texture_units});
    }
    var cam = physics.camera.Camera(*SurfaceDetail, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        sd,
        integrator,
        .{ 2, 4, -2 },
        std.math.pi,
    );
    errdefer cam.deinit(allocator);
    cam.global_ambient = .{ 0.025, 0.025, 0.025, 1.0 };
    cam.updateMVP();

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ 0.0, 5.0, 0.0, 0.0 },
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

    const ui_state: SurfaceDetailUI = .{};
    sd.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .view_camera = cam,
        .ctx = ctx,
        .lights = lights_buf,
        .materials = mats_buf,
    };

    sd.renderCubemap();
    errdefer sd.deleteCubemap();

    sd.renderMoon();
    errdefer sd.deleteMoon();

    const earth_vert = Compiler.runWithBytes(allocator, @embedFile("earth_vert.glsl")) catch @panic("shader compiler");
    defer allocator.free(earth_vert);
    const earth_frag = Compiler.runWithBytes(allocator, @embedFile("earth_frag.glsl")) catch @panic("shader compiler");
    defer allocator.free(earth_frag);

    sd.renderEarth(earth_vert, earth_frag);
    errdefer sd.deleteEarth();

    sd.renderDebugCross();
    errdefer sd.deleteDebugCross();

    sd.renderSphere();
    errdefer sd.deleteSphere();

    return sd;
}

pub fn deinit(self: *SurfaceDetail, allocator: std.mem.Allocator) void {
    if (self.moon_normal_map) |et| {
        et.deinit();
    }
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    self.materials.deinit();
    self.materials = undefined;
    self.lights.deinit();
    self.lights = undefined;
    self.deleteMoon();
    self.deleteEarth();
    self.deleteCubemap();
    self.deleteSphere();
    allocator.destroy(self);
}

pub fn draw(self: *SurfaceDetail, dt: f64) void {
    if (self.ui_state.light_updated) {
        self.moon_light_pos.setUniform3fv(self.ui_state.light_position);
        self.earth_light_pos.setUniform3fv(self.ui_state.light_position);
        const lp = self.ui_state.light_position;
        self.sphere_matrix.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
        self.ui_state.light_updated = false;
    }
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
    if (self.moon_normal_map) |t| {
        t.bind();
    }
    if (self.moon_texture) |t| {
        t.bind();
    }
    {
        const objects: [1]object.object = .{
            self.moon,
        };
        rhi.drawObjects(objects[0..]);
    }
    if (self.earth_normal_map) |t| {
        t.bind();
    }
    if (self.earth_texture) |t| {
        t.bind();
    }
    if (self.earth_height_map) |t| {
        t.bind();
    }
    {
        const objects: [1]object.object = .{
            self.earth,
        };
        rhi.drawObjects(objects[0..]);
    }
    {
        const objects: [1]object.object = .{
            self.sphere,
        };
        rhi.drawObjects(objects[0..]);
    }
    self.cross.draw(dt);
    self.ui_state.draw();
}

pub fn updateCamera(_: *SurfaceDetail) void {}

pub fn deleteCubemap(self: *SurfaceDetail) void {
    const objects: [1]object.object = .{
        self.cubemap,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderCubemap(self: *SurfaceDetail) void {
    const prog = rhi.createProgram();
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
            false,
        ),
    };
    parallelepiped.parallelepiped.mesh.linear_colorspace = false;
    if (self.cubemap_texture) |*bt| {
        var cm: assets.Cubemap = .{
            .path = "cgpoc\\cubemaps\\milkyway\\cubemap",
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
        bt.setupCubemap(images, prog, "f_cubemap") catch {
            self.cubemap_texture = null;
        };
    }
    self.cubemap = parallelepiped;
}

pub fn deleteMoon(self: *SurfaceDetail) void {
    const objects: [1]object.object = .{
        self.moon,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderMoon(self: *SurfaceDetail) void {
    const prog = rhi.createProgram();
    self.moon_normal_map = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.moon_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.moon_texture.?.texture_unit = 1;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .lighting = .blinn_phong,
            .fragment_shader = rhi.Texture.frag_shader(self.moon_normal_map),
            .frag_body = moon_frag_shader,
        };
        const partials = [_][]const u8{moon_vertex_shader};
        s.attach(self.allocator, @ptrCast(partials[0..]));
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(3, -4, -6));
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(0.5));
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
        .sphere = object.Sphere.initWithPrecision(
            prog,
            i_datas[0..],
            false,
            250,
        ),
    };
    if (self.moon_normal_map) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\surface_details\\moonNORMAL.jpg") catch null, prog, "f_samp") catch {
            self.moon_normal_map = null;
        };
    }
    if (self.moon_texture) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\PlanetPixelEmporium\\moonbump4kRGB.jpg") catch null, prog, "f_samp_1") catch {
            self.moon_texture = null;
        };
    }
    self.moon_light_pos = rhi.Uniform.init(prog, "f_moon_light_pos") catch @panic("uniform failed");
    self.moon_light_pos.setUniform3fv(.{ 3, 2, 1 });
    self.moon = sphere;
}

pub fn deleteEarth(self: *SurfaceDetail) void {
    const objects: [1]object.object = .{
        self.earth,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderEarth(self: *SurfaceDetail, vert: []u8, frag: []u8) void {
    const prog = rhi.createProgram();
    self.earth_normal_map = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.earth_normal_map.?.texture_unit = 2;
    self.earth_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.earth_texture.?.texture_unit = 3;
    self.earth_height_map = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.earth_height_map.?.texture_unit = 16;
    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);
    const frag_bindings = [_]usize{ 0, 1, 2, 3, 16 };
    const vert_bindings = [_]usize{16};
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .frag_body = if (!disable_bindless) frag else rhi.Shader.disableBindless(
                frag,
                frag_bindings[0..],
            ) catch @panic("bindless"),
            .bindless_vertex = !disable_bindless,
            .fragment_shader = .disabled,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(
            if (!disable_bindless) vert else rhi.Shader.disableBindless(vert, vert_bindings[0..]) catch @panic("bindless"),
        )[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
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
    const earth: object.object = .{
        .sphere = object.Sphere.initWithPrecision(
            prog,
            i_datas[0..],
            false,
            250,
        ),
    };
    if (self.earth_normal_map) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\surface_details\\earthspec1kNORMAL.jpg") catch null, prog, "f_samp_2") catch {
            self.earth_normal_map = null;
        };
    }
    if (self.earth_texture) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\PlanetPixelEmporium\\earthmap1k.jpg") catch null, prog, "f_samp_3") catch {
            self.earth_texture = null;
        };
    }
    if (self.earth_height_map) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\surface_details\\earthspec1kNEG.jpg") catch null, prog, "f_earth_heightmap") catch {
            self.earth_height_map = null;
        };
    }
    self.earth_light_pos = rhi.Uniform.init(prog, "f_earth_light_pos") catch @panic("failed to load earthlight uniform");
    self.earth_light_pos.setUniform3fv(.{ 1, 2, 3 });
    self.earth = earth;
}

pub fn deleteCross(self: *SurfaceDetail) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *SurfaceDetail) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, 0, 5),
        5,
    );
}

pub fn deleteSphere(self: *SurfaceDetail) void {
    const objects: [1]object.object = .{
        self.sphere,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn renderSphere(self: *SurfaceDetail) void {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .color,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(sphere_vertex_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    const m = math.matrix.uniformScale(0.125);
    i_datas[0] = .{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 1, 1, 1, 1 },
    };
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    const lp = self.ui_state.light_position;
    var sm: rhi.Uniform = rhi.Uniform.init(prog, "f_sphere_matrix") catch @panic("uniform failed");
    sm.setUniformMatrix(math.matrix.translate(lp[0], lp[1], lp[2]));
    self.sphere_matrix = sm;
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
const lighting = @import("../../../../lighting/lighting.zig");
const assets = @import("../../../../assets/assets.zig");
const SurfaceDetailUI = @import("SurfaceDetailUI.zig");
const Compiler = @import("../../../../../fssc/Compiler.zig");
