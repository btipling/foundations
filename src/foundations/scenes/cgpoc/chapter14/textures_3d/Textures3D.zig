view_camera: *physics.camera.Camera(*Textures3D, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

grid: object.object = .{ .norender = .{} },
grid_t_tex: ?rhi.Texture = null,
grid_t_nor: ?rhi.Texture = null,

sphere: object.object = .{ .norender = .{} },

striped_block: object.object = .{ .norender = .{} },

materials: rhi.Buffer,
lights: rhi.Buffer,

const Textures3D = @This();

const mats = [_]lighting.Material{
    lighting.materials.Gold,
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

    const bd: rhi.Buffer.buffer_data = .{ .materials = mats[0..] };
    var mats_buf = rhi.Buffer.init(bd);
    errdefer mats_buf.deinit();

    const lights = [_]lighting.Light{
        .{
            .ambient = [4]f32{ 0.1, 0.1, 0.1, 1.0 },
            .diffuse = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .specular = [4]f32{ 1.0, 1.0, 1.0, 1.0 },
            .location = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .direction = [4]f32{ 10, -10.0, -0.3, 0.0 },
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

    t3d.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .materials = mats_buf,
        .lights = lights_buf,
    };

    t3d.renderDebugCross();
    errdefer t3d.deleteCross();

    t3d.renderSphere();
    errdefer rhi.deleteObject(t3d.sphere);

    t3d.renderParallelepiped();
    errdefer rhi.deleteObject(t3d.striped_block);

    t3d.renderGrid();
    errdefer rhi.deleteObject(t3d.grid);

    return t3d;
}

pub fn deinit(self: *Textures3D, allocator: std.mem.Allocator) void {
    rhi.deleteObject(self.striped_block);
    rhi.deleteObject(self.sphere);
    if (self.grid_t_tex) |t| t.deinit();
    if (self.grid_t_nor) |t| t.deinit();
    self.deleteCross();
    self.lights.deinit();
    self.materials.deinit();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *Textures3D) void {}

pub fn draw(self: *Textures3D, dt: f64) void {
    self.view_camera.update(dt);
    {
        rhi.drawHorizon(self.sphere);
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
        rhi.drawObject(self.striped_block);
    }
    self.cross.draw(dt);
}

fn deleteCross(self: *Textures3D) void {
    self.cross.deinit(self.allocator);
}

fn renderDebugCross(self: *Textures3D) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0.01, -0.025, -0.025),
        5,
    );
}

fn renderSphere(self: *Textures3D) void {
    const prog = rhi.createProgram();

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
    s.attachAndLinkAll(self.allocator, shaders[0..]);
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
            false,
        ),
    };
    self.sphere = sphere;
}

fn renderParallelepiped(self: *Textures3D) void {
    const prog = rhi.createProgram();

    const vert = Compiler.runWithBytes(self.allocator, @embedFile("parallelepiped_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(vert);

    const frag = Compiler.runWithBytes(self.allocator, @embedFile("parallelepiped_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);
    const m = math.matrix.translateVec(.{ 0, 0, 2.5 });
    const i_datas = [_]rhi.instanceData{
        .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 1, 1 },
        },
    };

    var striped_block = .{ .parallelepiped = object.Parallelepiped.init(prog, i_datas[0..], false) };
    striped_block.parallelepiped.mesh.linear_colorspace = false;
    self.striped_block = striped_block;
}

fn renderGrid(self: *Textures3D) void {
    self.grid_t_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.grid_t_tex.?.wrap_s = c.GL_REPEAT;
    self.grid_t_tex.?.wrap_t = c.GL_REPEAT;
    self.grid_t_tex.?.texture_unit = 2;
    self.grid_t_nor = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.grid_t_nor.?.wrap_s = c.GL_REPEAT;
    self.grid_t_nor.?.wrap_t = c.GL_REPEAT;
    self.grid_t_nor.?.texture_unit = 4;
    var grid_model: *assets.Obj = undefined;
    if (self.ctx.obj_loader.loadAsset("cgpoc\\grid\\grid.obj") catch null) |o| {
        grid_model = o;
    } else {
        return;
    }
    const prog = rhi.createProgram();

    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);
    const frag_bindings = [_]usize{ 2, 4 };

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
    s.attachAndLinkAll(self.allocator, shaders[0..]);
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

    var grid_obj = .{ .parallelepiped = object.Parallelepiped.init(prog, i_datas[0..], false) };
    grid_obj.parallelepiped.mesh.linear_colorspace = false;

    if (self.grid_t_tex) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\grid\\wispy-grass-meadow_albedo.png") catch null, prog, "f_grid_samp") catch {
            self.grid_t_tex = null;
        };
    }
    if (self.grid_t_nor) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\grid\\wispy-grass-meadow_normal-ogl.png") catch null, prog, "f_normal_samp") catch {
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
const Compiler = @import("../../../../../compiler/Compiler.zig");
const object = @import("../../../../object/object.zig");
const lighting = @import("../../../../lighting/lighting.zig");
const assets = @import("../../../../assets/assets.zig");
