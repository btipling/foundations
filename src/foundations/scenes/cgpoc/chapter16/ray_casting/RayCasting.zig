view_camera: *physics.camera.Camera(*RayCasting, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
allocator: std.mem.Allocator,
ui_state: RayCastingUI,

materials: lighting.Material.SSBO,
lights: lighting.Light.SSBO,

cubemap: object.object = .{ .norender = .{} },
cubemap_texture: ?rhi.Texture = null,

brick_texture: ?rhi.Texture = null,
earth_texture: ?rhi.Texture = null,
cubemap_xp: ?rhi.Texture = null,
cubemap_xn: ?rhi.Texture = null,
cubemap_yp: ?rhi.Texture = null,
cubemap_yn: ?rhi.Texture = null,
cubemap_zp: ?rhi.Texture = null,
cubemap_zn: ?rhi.Texture = null,

cross: scenery.debug.Cross = undefined,

ray_cast_buffer: SSBO,

images: [RayCastingUI.num_images]Img = undefined,

const RayCasting = @This();

const mats = [_]lighting.Material{
    lighting.materials.Silver,
};

const cubemap_vert: []const u8 = @embedFile("../../../../shaders/cubemap_vert.glsl");

const Img = struct {
    prog: u32 = 0,
    tex: rhi.Texture = undefined,
    mem: []u8 = undefined,
    quad: object.object = .{ .norender = .{} },
    drawn: bool = false,
};

const texture_dims: usize = 512;
const num_channels: usize = 4;

pub const SceneData = extern struct {
    sphere_radius: [4]f32,
    sphere_position: [4]f32,
    sphere_color: [4]f32,
    box_position: [4]f32,
    box_dims: [4]f32,
    box_color: [4]f32,
    box_rotation: [4]f32,
    camera_position: [4]f32,
    camera_direction: [4]f32,
};

pub const binding_point: rhi.storage_buffer.storage_binding_point = .{ .ubo = 3 };
const SSBO = rhi.storage_buffer.Buffer([]const SceneData, binding_point, c.GL_DYNAMIC_COPY);

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Ray Casting",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *RayCasting {
    const rc = allocator.create(RayCasting) catch @panic("OOM");
    errdefer allocator.destroy(rc);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*RayCasting, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        rc,
        integrator,
        .{ 1, -5, 2 },
        0,
    );
    errdefer cam.deinit(allocator);

    const bd: []const lighting.Material = mats[0..];
    var mats_buf = lighting.Material.SSBO.init(bd, "materials");
    errdefer mats_buf.deinit();

    var lights: [RayCastingUI.num_images]lighting.Light = undefined;
    for (0..RayCastingUI.num_images) |i| {
        lights[i] = .{
            .ambient = [4]f32{ 0.2, 0.2, 0.2, 1.0 },
            .diffuse = [4]f32{ 0.7, 0.7, 0.70, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 3.0, 2.0, 4.0, 1.0 },
            .direction = [4]f32{ 0.5, -1.0, -0.3, 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        };
    }
    const ld: []const lighting.Light = lights[0..];
    var lights_buf = lighting.Light.SSBO.init(ld, "lights");
    errdefer lights_buf.deinit();

    var cd: [RayCastingUI.num_images]SceneData = undefined;
    for (0..RayCastingUI.num_images) |i| {
        cd[i] = .{
            .sphere_radius = .{ 2.5, 0, 0, 0 },
            .sphere_position = .{ 1, 0, -3, 1.0 },
            .sphere_color = .{ 0, 0, 1, 1 },
            .box_position = .{ 0.5, 0, 0, 0 },
            .box_dims = .{ 0.5, 0.5, 0.5, 0 },
            .box_color = .{ 1, 0, 0, 0 },
            .box_rotation = .{ 0, 0, 0, 0 },
            .camera_position = .{ 0, 0, 5, 1 },
            .camera_direction = .{ 0, 0, 1, 0 },
        };
    }
    var rc_buf = SSBO.init(cd[0..], "scene_data");
    errdefer rc_buf.deinit();
    var ui_state: RayCastingUI = .{};
    for (0..RayCastingUI.num_images) |i| {
        ui_state.data[i] = .{};
    }
    ui_state.updating = RayCastingUI.num_images - 1;

    rc.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .ctx = ctx,
        .view_camera = cam,
        .materials = mats_buf,
        .lights = lights_buf,
        .ray_cast_buffer = rc_buf,
    };

    rc.renderCubemap();
    errdefer rc.deleteCubemap();

    rc.renderDebugCross();
    errdefer rc.deleteCross();

    rc.images[0] = rc.renderImg("img_1", @embedFile("img_1.comp.glsl"), math.matrix.translate(3, 0, -24));
    errdefer rc.deleteImg(rc.images[0]);
    rc.images[1] = rc.renderImg("img_2", @embedFile("img_2.comp.glsl"), math.matrix.translate(3, 0, -20));
    errdefer rc.deleteImg(rc.images[1]);
    rc.images[2] = rc.renderImg("img_3", @embedFile("img_3.comp.glsl"), math.matrix.translate(3, 0, -16));
    errdefer rc.deleteImg(rc.images[2]);
    rc.images[3] = rc.renderImg("img_4", @embedFile("img_4.comp.glsl"), math.matrix.translate(3, 0, -12));
    errdefer rc.deleteImg(rc.images[3]);
    rc.images[4] = rc.renderImg("img_5", @embedFile("img_5.comp.glsl"), math.matrix.translate(3, 0, -8));
    errdefer rc.deleteImg(rc.images[4]);
    rc.images[5] = rc.renderImg("img_6", @embedFile("img_6.comp.glsl"), math.matrix.translate(3, 0, -4));
    errdefer rc.deleteImg(rc.images[5]);
    rc.images[6] = rc.renderImg("img_7", @embedFile("img_7.comp.glsl"), math.matrix.translate(3, 0, 0));
    errdefer rc.deleteImg(rc.images[6]);

    return rc;
}

pub fn deinit(self: *RayCasting, allocator: std.mem.Allocator) void {
    self.ray_cast_buffer.deinit();
    for (self.images) |i| {
        self.deleteImg(i);
    }
    self.ray_cast_buffer.deinit();
    self.deleteCross();
    self.deleteCubemap();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *RayCasting) void {}

pub fn draw(self: *RayCasting, dt: f64) void {
    self.rayCastScene();
    self.view_camera.update(dt);
    if (self.cubemap_texture) |t| {
        t.bind();
    }
    {
        rhi.drawHorizon(self.cubemap);
    }
    {
        self.brick_texture.?.bind();
        self.earth_texture.?.bind();

        self.cubemap_xp.?.bind();
        self.cubemap_xn.?.bind();
        self.cubemap_yp.?.bind();
        self.cubemap_yn.?.bind();
        self.cubemap_zp.?.bind();
        self.cubemap_zn.?.bind();

        for (self.images) |i| {
            i.tex.bind();
            rhi.drawObject(i.quad);
        }
    }
    self.cross.draw(dt);
    self.ui_state.draw();
    for (self.ui_state.data, 0..) |d, i| {
        if (!d.updated) continue;
        self.updateSceneData(i);
        self.ui_state.data[i].updated = false;
    }
}

fn rayCastScene(self: *RayCasting) void {
    for (self.images, 0..) |img, i| {
        if (img.drawn) continue;
        img.tex.bindWritableImage();
        c.glUseProgram(img.prog);
        c.glDispatchCompute(texture_dims, texture_dims, 1);
        c.glMemoryBarrier(c.GL_ALL_BARRIER_BITS);
        self.images[i].drawn = true;
    }
}

fn deleteCross(self: *RayCasting) void {
    self.cross.deinit(self.allocator);
}

pub fn allocateTextureMemory(self: *RayCasting) []u8 {
    var mem = self.allocator.alloc(u8, texture_dims * texture_dims * num_channels) catch @panic("OOM");
    for (0..texture_dims) |i| {
        for (0..texture_dims) |j| {
            mem[i * texture_dims * num_channels + j * num_channels + 0] = 255;
            mem[i * texture_dims * num_channels + j * num_channels + 1] = 128;
            mem[i * texture_dims * num_channels + j * num_channels + 2] = 255;
            mem[i * texture_dims * num_channels + j * num_channels + 3] = 255;
        }
    }
    return mem;
}

fn renderDebugCross(self: *RayCasting) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0.0, 0.0, 0.0),
        5,
    );
}

fn initSceneTextures(self: *RayCasting, prog: u32) bool {
    if (self.brick_texture) |_| if (self.earth_texture) |_| return false;
    if (self.brick_texture) |t| t.deinit();

    const disable_bindless = true; // disabling to keep compute ray tracing shaders simple

    var brick_texture = rhi.Texture.init(disable_bindless) catch @panic("no texture");
    brick_texture.texture_unit = 2;
    var earth_texture = rhi.Texture.init(disable_bindless) catch @panic("no texture");
    earth_texture.texture_unit = 3;

    var cubemap_xp = rhi.Texture.init(disable_bindless) catch @panic("no texture");
    cubemap_xp.texture_unit = 4;
    var cubemap_xn = rhi.Texture.init(disable_bindless) catch @panic("no texture");
    cubemap_xn.texture_unit = 5;

    var cubemap_yp = rhi.Texture.init(disable_bindless) catch @panic("no texture");
    cubemap_yp.texture_unit = 6;
    var cubemap_yn = rhi.Texture.init(disable_bindless) catch @panic("no texture");
    cubemap_yn.texture_unit = 7;

    var cubemap_zp = rhi.Texture.init(disable_bindless) catch @panic("no texture");
    cubemap_zp.texture_unit = 8;
    var cubemap_zn = rhi.Texture.init(disable_bindless) catch @panic("no texture");
    cubemap_zn.texture_unit = 9;

    self.brick_texture = brick_texture;
    self.earth_texture = earth_texture;

    self.cubemap_xp = cubemap_xp;
    self.cubemap_xn = cubemap_xn;
    self.cubemap_yp = cubemap_yp;
    self.cubemap_yn = cubemap_yn;
    self.cubemap_zp = cubemap_zp;
    self.cubemap_zn = cubemap_zn;

    self.brick_texture.?.setup(self.ctx.textures_loader.loadAsset("cgpoc\\luna\\brick1.jpg") catch null, prog, "f_box_tex", "box_texture") catch @panic("no texture");
    self.earth_texture.?.setup(self.ctx.textures_loader.loadAsset("cgpoc\\PlanetPixelEmporium\\earthmap1k.jpg") catch null, prog, "f_sphere_tex", "sphere_texture") catch @panic("no texture");

    self.cubemap_xp.?.setup(self.ctx.textures_loader.loadAsset("cgpoc\\cubemaps\\LakeIslands\\cubeMap\\xp.jpg") catch null, prog, "f_xp_tex", "f_xp_tex") catch @panic("no texture");
    self.cubemap_xn.?.setup(self.ctx.textures_loader.loadAsset("cgpoc\\cubemaps\\LakeIslands\\cubeMap\\xn.jpg") catch null, prog, "f_xn_tex", "f_xn_tex") catch @panic("no texture");
    self.cubemap_yp.?.setup(self.ctx.textures_loader.loadAsset("cgpoc\\cubemaps\\LakeIslands\\cubeMap\\yp.jpg") catch null, prog, "f_yp_tex", "f_yp_tex") catch @panic("no texture");
    self.cubemap_yn.?.setup(self.ctx.textures_loader.loadAsset("cgpoc\\cubemaps\\LakeIslands\\cubeMap\\yn.jpg") catch null, prog, "f_yn_tex", "f_yn_tex") catch @panic("no texture");
    self.cubemap_zp.?.setup(self.ctx.textures_loader.loadAsset("cgpoc\\cubemaps\\LakeIslands\\cubeMap\\zp.jpg") catch null, prog, "f_zp_tex", "f_zp_tex") catch @panic("no texture");
    self.cubemap_zn.?.setup(self.ctx.textures_loader.loadAsset("cgpoc\\cubemaps\\LakeIslands\\cubeMap\\zn.jpg") catch null, prog, "f_zn_tex", "f_zn_tex") catch @panic("no texture");

    return true;
}

fn deleteImg(self: *RayCasting, img: Img) void {
    c.glDeleteProgram(img.prog);
    self.allocator.free(img.mem);
    img.tex.deinit();
    rhi.deleteObject(img.quad);
}

fn renderImg(self: *RayCasting, name: [:0]const u8, compute_shader: []const u8, translation: math.matrix) Img {
    var img: Img = .{
        .mem = self.allocateTextureMemory(),
        .tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch @panic("unable to create reflection texture"),
    };
    {
        img.prog = rhi.createProgram(name);
        const comp = Compiler.runWithBytes(self.allocator, compute_shader) catch @panic("shader compiler");
        defer self.allocator.free(comp);

        const shaders = [_]rhi.Shader.ShaderData{
            .{ .source = comp, .shader_type = c.GL_COMPUTE_SHADER },
        };
        const s: rhi.Shader = .{
            .program = img.prog,
        };
        s.attachAndLinkAll(self.allocator, shaders[0..], name);
        if (!self.initSceneTextures(img.prog)) {
            self.brick_texture.?.addUniform(img.prog, "f_box_tex") catch @panic("no uniform");
            self.earth_texture.?.addUniform(img.prog, "f_sphere_tex") catch @panic("no uniform");
        }
    }
    {
        img.tex.texture_unit = 1;
        const prog = rhi.createProgram(name);
        const frag_bindings = [_]usize{1};
        const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);

        const vert = Compiler.runWithBytes(self.allocator, @embedFile("quad_vert.glsl")) catch @panic("shader compiler");
        defer self.allocator.free(vert);

        var frag = Compiler.runWithBytes(self.allocator, @embedFile("quad_frag.glsl")) catch @panic("shader compiler");
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
        s.attachAndLinkAll(self.allocator, shaders[0..], name);
        var m = translation;
        m = math.matrix.transformMatrix(m, math.matrix.uniformScale(3));
        m = math.matrix.transformMatrix(m, math.matrix.rotationY(std.math.pi / 2.0));
        m = math.matrix.transformMatrix(m, math.matrix.rotationZ(-(std.math.pi / 2.0)));
        const i_datas = [_]rhi.instanceData{
            .{
                .t_column0 = m.columns[0],
                .t_column1 = m.columns[1],
                .t_column2 = m.columns[2],
                .t_column3 = m.columns[3],
                .color = .{ 1, 0, 1, 1 },
            },
        };
        var grid_obj: object.object = .{ .quad = object.Quad.initPlane(prog, i_datas[0..], name) };
        grid_obj.quad.mesh.linear_colorspace = false;
        img.quad = grid_obj;

        img.tex.setupWriteable(
            img.mem,
            prog,
            "f_texture",
            name,
            texture_dims,
            texture_dims,
        ) catch @panic("unable to setup reflection depth texture");
    }
    return img;
}

fn updateSceneData(self: *RayCasting, i: usize) void {
    var cd: [RayCastingUI.num_images]SceneData = undefined;
    for (cd, 0..) |_, j| {
        var sd = cd[j];
        const d = self.ui_state.data[j];
        const sp = d.sphere_pos;
        const sc = d.sphere_color;
        const bd = d.box_dim;
        const bp = d.box_pos;
        const bc = d.box_color;
        const br = d.box_rot;
        const cpos = d.camera_pos;
        const cdir: math.vector.vec4 = d.camera_dir;

        sd.sphere_radius = .{ d.sphere_radius, 0, 0, 0 };
        sd.sphere_position = .{ sp[0], sp[1], sp[2], 1.0 };
        sd.sphere_color = .{ sc[0], sc[1], sc[2], 1 };

        sd.box_position = .{ bp[0], bp[1], bp[2], 0 };
        sd.box_dims = .{ bd, bd, bd, 0 };
        sd.box_color = .{ bc[0], bc[1], bc[2], 1 };
        sd.box_rotation = .{ br[0], br[1], br[2], 0 };

        sd.camera_position = cpos;
        sd.camera_direction = cdir;
        cd[j] = sd;
    }
    self.ray_cast_buffer.update(cd[0..]);
    self.updateLights();
    self.images[i].drawn = false;
}

fn updateLights(self: *RayCasting) void {
    var lights: [RayCastingUI.num_images]lighting.Light = undefined;
    for (0..RayCastingUI.num_images) |i| {
        lights[i] = .{
            .ambient = [4]f32{ 0.2, 0.2, 0.2, 1.0 },
            .diffuse = [4]f32{ 0.7, 0.7, 0.70, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = self.ui_state.data[i].light_pos,
            .direction = [4]f32{ 0.5, -1.0, -0.3, 0.0 },
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        };
    }
    self.lights.deinit();
    const ld: []const lighting.Light = lights[0..];
    var lights_buf = lighting.Light.SSBO.init(ld, "lights");
    errdefer lights_buf.deinit();
    self.lights = lights_buf;
}

pub fn deleteCubemap(self: *RayCasting) void {
    const objects: [1]object.object = .{
        self.cubemap,
    };
    rhi.deleteObjects(objects[0..]);
    if (self.cubemap_texture) |t| {
        t.deinit();
    }
}

pub fn renderCubemap(self: *RayCasting) void {
    const prog = rhi.createProgram("cubemap");
    self.cubemap_texture = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    {
        var s: rhi.Shader = .{
            .program = prog,
            .cubemap = true,
            .instance_data = true,
            .fragment_shader = .texture,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(cubemap_vert)[0..], "cubemap");
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
const physics = @import("../../../../physics/physics.zig");
const math = @import("../../../../math/math.zig");
const scenes = @import("../../../scenes.zig");
const scenery = @import("../../../../scenery/scenery.zig");
const Compiler = @import("../../../../../fssc/Compiler.zig");
const RayCastingUI = @import("RayCastingUI.zig");
const object = @import("../../../../object/object.zig");
const lighting = @import("../../../../lighting/lighting.zig");
const assets = @import("../../../../assets/assets.zig");
