view_camera: *physics.camera.Camera(*Textures3D, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,
ui_state: Textures3DUI,

shadowpass: *rendering.DirectionalShadowPass = undefined,

grid: object.object = .{ .norender = .{} },
grid_t_tex: ?rhi.Texture = null,
grid_t_nor: ?rhi.Texture = null,

sphere: object.object = .{ .norender = .{} },
sky_tex: ?rhi.Texture = null,
sky_rot: ?rhi.Uniform = null,
sky_dep: ?rhi.Uniform = null,
sky_depth: f32 = 0.0,

striped_block: object.object = .{ .norender = .{} },
striped_tex: ?rhi.Texture = null,

marbled_block: object.object = .{ .norender = .{} },
marbled_tex: ?rhi.Texture = null,

wood_block: object.object = .{ .norender = .{} },
wood_tex: ?rhi.Texture = null,

static_block: object.object = .{ .norender = .{} },
static_tex: ?rhi.Texture = null,

wave_block: object.object = .{ .norender = .{} },
wave_tex: ?rhi.Texture = null,

materials: lighting.Material.SSBO,
lights: lighting.Light.SSBO,
light_m: math.matrix,

shadow_objects: [6]rendering.DirectionalShadowPass.ShadowObject = undefined,

const Textures3D = @This();

const tex_dims: usize = 256;

const mats = [_]lighting.Material{
    lighting.materials.Silver,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "3D Textures",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Textures3D {
    const t3d = allocator.create(Textures3D) catch @panic("OOM");
    errdefer allocator.destroy(t3d);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*Textures3D, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        t3d,
        integrator,
        .{ 2, -5, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const bd: []const lighting.Material = mats[0..];
    var mats_buf = lighting.Material.SSBO.init(bd, "materials");
    errdefer mats_buf.deinit();

    const shadowpass = rendering.DirectionalShadowPass.init(allocator, ctx, 1);
    errdefer shadowpass.deinit(allocator);

    var light_direction: math.vector.vec4 = .{ 0, 1, 0, 0 };
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.rotationX(std.math.pi));
    m = math.matrix.transformMatrix(m, math.matrix.rotationY(std.math.pi / 2.0));
    m = math.matrix.transformMatrix(m, math.matrix.rotationZ(std.math.pi / 2.0));
    light_direction = math.matrix.transformVector(m, light_direction);
    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = light_direction,
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        },
    };
    const ld: []const lighting.Light = lights[0..];
    var lights_buf = lighting.Light.SSBO.init(ld, "lights");
    errdefer lights_buf.deinit();

    const ui_state: Textures3DUI = .{};
    t3d.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
        .shadowpass = shadowpass,
        .light_m = m,
        .ui_state = ui_state,
    };

    t3d.renderDebugCross();
    errdefer t3d.deleteCross();

    t3d.renderSphere();
    errdefer rhi.deleteObject(t3d.sphere);

    t3d.renderStripedBlock();
    errdefer rhi.deleteObject(t3d.striped_block);
    t3d.shadow_objects[0] = .{ .obj = t3d.striped_block };

    t3d.renderMarbledBlock();
    errdefer rhi.deleteObject(t3d.marbled_block);
    t3d.shadow_objects[1] = .{ .obj = t3d.marbled_block };

    t3d.renderWoodBlock();
    errdefer rhi.deleteObject(t3d.wood_block);
    t3d.shadow_objects[2] = .{ .obj = t3d.wood_block };

    t3d.renderStaticBlock();
    errdefer rhi.deleteObject(t3d.static_block);
    t3d.shadow_objects[3] = .{ .obj = t3d.static_block };

    t3d.renderWaveBlock();
    errdefer rhi.deleteObject(t3d.wave_block);
    t3d.shadow_objects[4] = .{ .obj = t3d.wave_block };

    t3d.renderGrid();
    errdefer rhi.deleteObject(t3d.grid);
    t3d.shadow_objects[5] = .{ .obj = t3d.grid };

    t3d.shadowpass.updateShdowObjects(t3d.shadow_objects[0..]);

    return t3d;
}

pub fn deinit(self: *Textures3D, allocator: std.mem.Allocator) void {
    rhi.deleteObject(self.marbled_block);
    rhi.deleteObject(self.striped_block);
    rhi.deleteObject(self.wood_block);
    rhi.deleteObject(self.static_block);
    rhi.deleteObject(self.wave_block);
    rhi.deleteObject(self.sphere);
    rhi.deleteObject(self.grid);
    if (self.grid_t_tex) |t| t.deinit();
    if (self.grid_t_nor) |t| t.deinit();
    if (self.striped_tex) |t| t.deinit();
    if (self.marbled_tex) |t| t.deinit();
    if (self.static_tex) |t| t.deinit();
    if (self.wave_tex) |t| t.deinit();
    self.deleteCross();
    self.shadowpass.deinit(allocator);
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *Textures3D) void {}

fn updateLights(self: *Textures3D) void {
    var lp = math.vector.normalize(@as(math.vector.vec3, self.ui_state.light_position));
    lp = math.vector.mul(self.ui_state.light_distance, lp);
    const lr = self.ui_state.light_rotation;
    var mt = math.matrix.transformMatrix(math.matrix.identity(), math.matrix.translate(lp[0], lp[1], lp[2]));
    mt = math.matrix.transformMatrix(mt, math.matrix.rotationX(lr[0]));
    mt = math.matrix.transformMatrix(mt, math.matrix.rotationY(lr[1]));
    mt = math.matrix.transformMatrix(mt, math.matrix.rotationZ(lr[2]));
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.rotationX(lr[0]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationY(-lr[1]));
    m = math.matrix.transformMatrix(m, math.matrix.rotationZ(lr[2]));
    self.light_m = mt;
    const forward: math.vector.vec4 = .{ 0, -1, 0, 0 };
    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = math.vector.mul(-1, math.matrix.transformVector(m, forward)),
            .cutoff = 0.0,
            .exponent = 0.0,
            .attenuation_constant = 1.0,
            .attenuation_linear = 0.0,
            .attenuation_quadratic = 0.0,
            .light_kind = .positional,
        },
    };
    self.lights.deinit();
    const ld: []const lighting.Light = lights[0..];
    var lights_buf = lighting.Light.SSBO.init(ld, "lights");
    errdefer lights_buf.deinit();
    self.lights = lights_buf;
    self.shadowpass.update(self.light_m);
    self.view_camera.f_shadow_view_m = self.shadowpass.light_view_renderpass;
}

pub fn draw(self: *Textures3D, dt: f64) void {
    if (self.ui_state.light_updated) {
        self.updateLights();
        self.ui_state.light_updated = false;
    }
    self.view_camera.update(dt);
    {
        self.shadowpass.genShadowMap();
    }
    {
        if (self.sky_tex) |t| {
            t.bind();
        }
        const dtt = dt * 0.1;
        self.sky_rot.?.setUniformMatrix(math.matrix.rotationX(@floatCast(dtt)));
        self.sky_depth += @floatCast(dtt * 0.00003);
        if (self.sky_depth >= 0.99) {
            self.sky_depth = 0.01;
        }
        self.sky_dep.?.setUniform1f(self.sky_depth);
        rhi.drawHorizon(self.sphere);
    }
    {
        self.shadowpass.shadowmap.bind();
    }
    if (self.grid_t_tex) |t| {
        t.bind();
    }
    if (self.grid_t_nor) |t| {
        t.bind();
    }
    {
        rhi.drawObject(self.grid);
    }
    {
        if (self.striped_tex) |t| {
            t.bind();
        }
        rhi.drawObject(self.striped_block);
    }
    {
        if (self.marbled_tex) |t| {
            t.bind();
        }
        rhi.drawObject(self.marbled_block);
    }
    {
        if (self.wood_tex) |t| {
            t.bind();
        }
        rhi.drawObject(self.wood_block);
    }
    {
        if (self.static_tex) |t| {
            t.bind();
        }
        rhi.drawObject(self.static_block);
    }
    {
        if (self.wave_tex) |t| {
            t.bind();
        }
        rhi.drawObject(self.wave_block);
    }
    self.cross.draw(dt);
    self.ui_state.draw();
}

fn deleteCross(self: *Textures3D) void {
    self.cross.deinit(self.allocator);
}

fn renderDebugCross(self: *Textures3D) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0.05, -0.025, -0.025),
        5,
    );
}

fn renderSphere(self: *Textures3D) void {
    const prog = rhi.createProgram("sky_dome");
    self.sky_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.sky_tex.?.texture_unit = 1;
    const frag_bindings = [_]usize{1};
    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("sphere_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);
    var frag = Compiler.runWithBytes(self.allocator, @embedFile("sphere_frag.glsl")) catch @panic("shader compiler");
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
    s.attachAndLinkAll(self.allocator, shaders[0..], "sky_dome");
    const m = math.matrix.uniformScale(1);
    var i_datas: [1]rhi.instanceData = .{.{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 0.529, 0.808, 0.922, 1 },
    }};
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            "skydome",
        ),
    };
    if (self.sky_tex) |*t| {
        const data = self.ctx.textures_3d_loader.loadAsset("cgpoc\\cloud.vol") catch null;
        t.setup3D(
            data,
            tex_dims,
            tex_dims,
            tex_dims,
            prog,
            c.GL_CLAMP_TO_EDGE,
            "f_tex_samp",
            "skydone_3d",
        ) catch {
            self.sky_tex = null;
        };
    }
    const sr = rhi.Uniform.init(prog, "f_sky_rot") catch @panic("no uniform");
    sr.setUniformMatrix(math.matrix.identity());
    self.sky_rot = sr;
    const sd = rhi.Uniform.init(prog, "f_sky_dep") catch @panic("no uniform");
    sd.setUniform1f(0);
    self.sky_dep = sd;
    self.sphere = sphere;
}

fn renderWaveBlock(self: *Textures3D) void {
    const m = math.matrix.translateVec(.{ 0, 2.5, 0 });
    const block = self.renderParallelepiped(m);
    self.wave_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.wave_tex.?.texture_unit = 1;
    if (self.wave_tex) |*t| {
        const data = self.ctx.textures_3d_loader.loadAsset("cgpoc\\wave.vol") catch null;
        t.setup3D(
            data,
            tex_dims,
            tex_dims,
            tex_dims,
            block.mesh.program,
            c.GL_CLAMP_TO_EDGE,
            "f_tex_samp",
            "wave_3d",
        ) catch {
            self.wave_tex = null;
        };
    }

    self.wave_block = .{ .parallelepiped = block };
}

fn renderStaticBlock(self: *Textures3D) void {
    const m = math.matrix.translateVec(.{ 0, -2.5, 0 });
    const block = self.renderParallelepiped(m);
    self.static_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.static_tex.?.texture_unit = 1;
    if (self.static_tex) |*t| {
        const data = self.ctx.textures_3d_loader.loadAsset("cgpoc\\static.vol") catch null;
        t.setup3D(
            data,
            tex_dims,
            tex_dims,
            tex_dims,
            block.mesh.program,
            c.GL_CLAMP_TO_EDGE,
            "f_tex_samp",
            "static_3d",
        ) catch {
            self.static_tex = null;
        };
    }

    self.static_block = .{ .parallelepiped = block };
}

fn renderWoodBlock(self: *Textures3D) void {
    const m = math.matrix.translateVec(.{ 0, -2.5, 2.5 });
    const block = self.renderParallelepiped(m);
    self.wood_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.wood_tex.?.texture_unit = 1;
    if (self.wood_tex) |*t| {
        const data = self.ctx.textures_3d_loader.loadAsset("cgpoc\\wood.vol") catch null;
        t.setup3D(
            data,
            tex_dims,
            tex_dims,
            tex_dims,
            block.mesh.program,
            c.GL_CLAMP_TO_EDGE,
            "f_tex_samp",
            "wood_3d",
        ) catch {
            self.wood_tex = null;
        };
    }

    self.wood_block = .{ .parallelepiped = block };
}

fn renderMarbledBlock(self: *Textures3D) void {
    const m = math.matrix.translateVec(.{ 0, 2.5, 2.5 });
    const block = self.renderParallelepiped(m);
    self.marbled_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.marbled_tex.?.texture_unit = 1;
    if (self.marbled_tex) |*t| {
        const data = self.ctx.textures_3d_loader.loadAsset("cgpoc\\marble.vol") catch null;
        t.setup3D(
            data,
            tex_dims,
            tex_dims,
            tex_dims,
            block.mesh.program,
            c.GL_CLAMP_TO_EDGE,
            "f_tex_samp",
            "marbel_3d",
        ) catch {
            self.marbled_tex = null;
        };
    }

    self.marbled_block = .{ .parallelepiped = block };
}

fn renderStripedBlock(self: *Textures3D) void {
    const m = math.matrix.translateVec(.{ 0, 0, 2.5 });
    const block = self.renderParallelepiped(m);
    self.striped_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.striped_tex.?.texture_unit = 1;
    if (self.striped_tex) |*t| {
        const data = self.ctx.textures_3d_loader.loadAsset("cgpoc\\striped.vol") catch null;
        t.setup3D(
            data,
            tex_dims,
            tex_dims,
            tex_dims,
            block.mesh.program,
            c.GL_CLAMP_TO_EDGE,
            "f_tex_samp",
            "striped_3d",
        ) catch {
            self.striped_tex = null;
        };
    }

    self.striped_block = .{ .parallelepiped = block };
}

fn renderParallelepiped(self: *Textures3D, m: math.matrix) object.Parallelepiped {
    const prog = rhi.createProgram("block");

    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);
    const frag_bindings = [_]usize{1};
    const vert = Compiler.runWithBytes(self.allocator, @embedFile("parallelepiped_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    var frag = Compiler.runWithBytes(self.allocator, @embedFile("parallelepiped_frag.glsl")) catch @panic("shader compiler");
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
    s.attachAndLinkAll(self.allocator, shaders[0..], "block");
    const i_datas = [_]rhi.instanceData{
        .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        },
    };

    var block = object.Parallelepiped.init(prog, i_datas[0..], "block");
    block.mesh.linear_colorspace = true;
    return block;
}

fn renderGrid(self: *Textures3D) void {
    self.grid_t_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.grid_t_tex.?.wrap_s = c.GL_REPEAT;
    self.grid_t_tex.?.wrap_t = c.GL_REPEAT;
    self.grid_t_tex.?.texture_unit = 2;
    self.grid_t_nor = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.grid_t_nor.?.wrap_s = c.GL_REPEAT;
    self.grid_t_nor.?.wrap_t = c.GL_REPEAT;
    self.grid_t_nor.?.texture_unit = 3;
    var grid_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\grid\\grid.obj") catch null) |o| {
        grid_model = o;
    } else {
        return;
    }
    const prog = rhi.createProgram("ground");

    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);
    const frag_bindings = [_]usize{ 1, 2, 3 };

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("grid_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    var frag = Compiler.runWithBytes(self.allocator, @embedFile("grid_frag.glsl")) catch @panic("shader compiler");
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
    s.attachAndLinkAll(self.allocator, shaders[0..], "ground");
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translateVec(.{ -0.5, -500, -500 }));
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

    var grid_obj: object.object = .{ .parallelepiped = object.Parallelepiped.init(prog, i_datas[0..], "ground") };
    grid_obj.parallelepiped.mesh.linear_colorspace = true;

    if (self.grid_t_tex) |*t| {
        t.setup(
            self.ctx.textures_loader.loadAsset("cgpoc\\grid\\wispy-grass-meadow_albedo.png") catch null,
            prog,
            "f_grid_samp",
            "grass",
        ) catch {
            self.grid_t_tex = null;
        };
    }
    if (self.grid_t_nor) |*t| {
        t.setup(
            self.ctx.textures_loader.loadAsset("cgpoc\\grid\\wispy-grass-meadow_normal-ogl.png") catch null,
            prog,
            "f_normal_samp",
            "grass_normals",
        ) catch {
            self.grid_t_nor = null;
        };
    }

    self.grid = grid_obj;
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
const Textures3DUI = @import("Textures3DUI.zig");
