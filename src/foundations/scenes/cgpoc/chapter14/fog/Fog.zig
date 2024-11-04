view_camera: *physics.camera.Camera(*Fog, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

sphere: object.object = .{ .norender = .{} },

grid: object.object = .{ .norender = .{} },
grid_t_tex: ?rhi.Texture = null,
grid_t_hig: ?rhi.Texture = null,
grid_t_nor: ?rhi.Texture = null,

materials: lighting.Material.SSBO,
lights: lighting.Light.SSBO,

const Fog = @This();

const mats = [_]lighting.Material{
    lighting.materials.Silver,
};

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Fog",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Fog {
    const fog = allocator.create(Fog) catch @panic("OOM");
    errdefer allocator.destroy(fog);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*Fog, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        fog,
        integrator,
        .{ 2, -10, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const bd: []const lighting.Material = mats[0..];
    var mats_buf = lighting.Material.SSBO.init(bd, "materials");
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ 5, -1.0, -0.3, 0.0 },
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

    fog.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    fog.renderDebugCross();
    errdefer fog.deleteCross();

    fog.renderSphere();
    errdefer rhi.deleteObject(fog.sphere);

    fog.renderGrid();
    errdefer rhi.deleteObject(fog.grid);

    return fog;
}

pub fn deinit(self: *Fog, allocator: std.mem.Allocator) void {
    rhi.deleteObject(self.grid);
    rhi.deleteObject(self.sphere);
    if (self.grid_t_tex) |t| t.deinit();
    if (self.grid_t_hig) |t| t.deinit();
    if (self.grid_t_nor) |t| t.deinit();
    self.deleteCross();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *Fog) void {}

pub fn draw(self: *Fog, dt: f64) void {
    self.view_camera.update(dt);
    {
        rhi.drawHorizon(self.sphere);
    }
    if (self.grid_t_tex) |t| {
        t.bind();
    }
    if (self.grid_t_hig) |t| {
        t.bind();
    }
    if (self.grid_t_nor) |t| {
        t.bind();
    }
    {
        rhi.drawObject(self.grid);
    }
    self.cross.draw(dt);
}

fn deleteCross(self: *Fog) void {
    self.cross.deinit(self.allocator);
}

fn renderDebugCross(self: *Fog) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, -0.025, -0.025),
        5,
    );
}

fn renderSphere(self: *Fog) void {
    const prog = rhi.createProgram("sky_dome");

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("sphere_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);
    const frag = Compiler.runWithBytes(self.allocator, @embedFile("sphere_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);

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
        .color = .{ 0.7, 0.8, 0.9, 1 },
    }};
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            "skydome",
        ),
    };
    self.sphere = sphere;
}

fn renderGrid(self: *Fog) void {
    self.grid_t_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.grid_t_tex.?.texture_unit = 2;
    self.grid_t_hig = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.grid_t_hig.?.texture_unit = 3;
    self.grid_t_nor = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.grid_t_nor.?.texture_unit = 4;
    var grid_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\grid\\grid.obj") catch null) |o| {
        grid_model = o;
    } else {
        return;
    }
    const prog = rhi.createProgram("mountains");

    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);
    const frag_bindings = [_]usize{ 2, 4 };
    const vert_bindings = [_]usize{3};

    var vert = Compiler.runWithBytes(self.allocator, @embedFile("grid_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);
    vert = if (!disable_bindless) vert else rhi.Shader.disableBindless(
        vert,
        vert_bindings[0..],
    ) catch @panic("bindless");

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
    s.attachAndLinkAll(self.allocator, shaders[0..], "mountains");
    const m = math.matrix.uniformScale(500);
    var i_datas: [1]rhi.instanceData = .{.{
        .t_column0 = m.columns[0],
        .t_column1 = m.columns[1],
        .t_column2 = m.columns[2],
        .t_column3 = m.columns[3],
        .color = .{ 1, 0, 1, 1 },
    }};
    var grid_obj: object.object = grid_model.toObject(prog, i_datas[0..], "mountains");
    grid_obj.obj.mesh.linear_colorspace = true;

    if (self.grid_t_tex) |*t| {
        t.setup(
            self.ctx.textures_loader.loadAsset("cgpoc\\grid\\rough-igneous-rock-albedo.png") catch null,
            prog,
            "f_grid_samp",
            "rock_ground",
        ) catch {
            self.grid_t_tex = null;
        };
    }
    if (self.grid_t_hig) |*t| {
        t.setup(
            self.ctx.textures_loader.loadAsset("cgpoc\\grid\\rough-igneous-rock-height.png") catch null,
            prog,
            "f_height_samp",
            "rock_height",
        ) catch {
            self.grid_t_hig = null;
        };
    }
    if (self.grid_t_nor) |*t| {
        t.setup(
            self.ctx.textures_loader.loadAsset("cgpoc\\grid\\rough-igneous-rock-normal-ogl.png") catch null,
            prog,
            "f_normal_samp",
            "rock_normal",
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
