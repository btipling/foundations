view_camera: *physics.camera.Camera(*TerrainTessallator, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

terrain_program: u32 = undefined,
terrain_vao: u32 = undefined,
terrain_m: math.matrix = math.matrix.identity(),
terrain_u: rhi.Uniform = undefined,
terrain_t_map: ?rhi.Texture = null,
terrain_t_tex: ?rhi.Texture = null,

const TerrainTessallator = @This();

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Terrain Tessellator",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *TerrainTessallator {
    const tt = allocator.create(TerrainTessallator) catch @panic("OOM");
    errdefer allocator.destroy(tt);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*TerrainTessallator, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        tt,
        integrator,
        .{ 2, -4, 2 },
        0,
    );
    errdefer cam.deinit(allocator);

    tt.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
    };

    tt.renderTerrain();
    errdefer tt.deleteTerrain();

    tt.renderDebugCross();
    errdefer tt.deleteCross();

    return tt;
}

pub fn deinit(self: *TerrainTessallator, allocator: std.mem.Allocator) void {
    self.deleteCross();
    self.deleteTerrain();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *TerrainTessallator) void {}

pub fn draw(self: *TerrainTessallator, dt: f64) void {
    self.view_camera.update(dt);
    if (self.terrain_t_tex) |t| {
        t.bind();
    }
    {
        rhi.runTessalation(self.terrain_program, 1);
    }
    self.cross.draw(dt);
}

pub fn deleteCross(self: *TerrainTessallator) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *TerrainTessallator) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, -0.025, -0.025),
        5,
    );
}

pub fn deleteTerrain(self: *TerrainTessallator) void {
    rhi.deletePrimitive(self.terrain_program, self.terrain_vao, 0);
}

pub fn renderTerrain(self: *TerrainTessallator) void {
    const prog = rhi.createProgram();
    const vao = rhi.createVAO();

    self.terrain_t_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.terrain_t_tex.?.texture_unit = 2;

    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);
    const frag_bindings = [_]usize{2};
    const terrain_vert = Compiler.runWithBytes(self.allocator, @embedFile("terrain_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_vert);
    var terrain_frag = Compiler.runWithBytes(self.allocator, @embedFile("terrain_frag.glsl")) catch @panic("shader compiler");
    terrain_frag = if (!disable_bindless) terrain_frag else rhi.Shader.disableBindless(
        terrain_frag,
        frag_bindings[0..],
    ) catch @panic("bindless");
    defer self.allocator.free(terrain_frag);
    const terrain_tcs = Compiler.runWithBytes(self.allocator, @embedFile("terrain_tcs.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_tcs);
    const terrain_tes = Compiler.runWithBytes(self.allocator, @embedFile("terrain_tes.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_tes);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = terrain_vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = terrain_frag, .shader_type = c.GL_FRAGMENT_SHADER },
        .{ .source = terrain_tcs, .shader_type = c.GL_TESS_CONTROL_SHADER },
        .{ .source = terrain_tes, .shader_type = c.GL_TESS_EVALUATION_SHADER },
    };

    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);

    if (self.terrain_t_tex) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\tessellation\\square_moon_map.jpg") catch null, prog, "f_terrain_samp") catch {
            self.terrain_t_tex = null;
        };
    }

    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translate(-3, 5, 0));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(10));
    var u = rhi.Uniform.init(prog, "f_terrain_m") catch @panic("uniform");
    u.setUniformMatrix(m);
    self.terrain_u = u;
    self.terrain_program = prog;
    self.terrain_vao = vao;
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
