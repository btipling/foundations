view_camera: *physics.camera.Camera(*LodTessellator, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,
ui_state: LodTessellatorUI = undefined,

terrain_program: u32 = undefined,
terrain_vao: u32 = undefined,
terrain_m: math.matrix = math.matrix.identity(),
terrain_u: rhi.Uniform = undefined,
terrain_t_map: ?rhi.Texture = null,
terrain_t_tex: ?rhi.Texture = null,

const LodTessellator = @This();

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "LOD Tessellator",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *LodTessellator {
    const tt = allocator.create(LodTessellator) catch @panic("OOM");
    errdefer allocator.destroy(tt);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*LodTessellator, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        tt,
        integrator,
        .{ 2, -4, 2 },
        0,
    );
    errdefer cam.deinit(allocator);

    const ui_state: LodTessellatorUI = .{};
    tt.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
        .ui_state = ui_state,
    };

    tt.renderTerrain();
    errdefer tt.deleteTerrain();

    tt.renderDebugCross();
    errdefer tt.deleteCross();

    return tt;
}

pub fn deinit(self: *LodTessellator, allocator: std.mem.Allocator) void {
    self.deleteCross();
    self.deleteTerrain();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *LodTessellator) void {}

pub fn draw(self: *LodTessellator, dt: f64) void {
    self.view_camera.update(dt);
    if (self.terrain_t_map) |t| {
        t.bind();
    }
    if (self.terrain_t_tex) |t| {
        t.bind();
    }
    {
        c.glLineWidth(5.0);
        if (self.ui_state.wire_frame) {
            c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);
        }
        rhi.runTesselationInstanced(self.terrain_program, 4, 128 * 128);
        c.glLineWidth(1.0);
        if (self.ui_state.wire_frame) {
            c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_FILL);
        }
    }
    self.cross.draw(dt);
    self.ui_state.draw();
}

pub fn deleteCross(self: *LodTessellator) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *LodTessellator) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(5, 50, 50),
        5,
    );
}

pub fn deleteTerrain(self: *LodTessellator) void {
    rhi.deletePrimitive(self.terrain_program, self.terrain_vao, 0);
}

pub fn renderTerrain(self: *LodTessellator) void {
    const prog = rhi.createProgram("terrain");
    const vao = rhi.createVAO();

    self.terrain_t_tex = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.terrain_t_tex.?.texture_unit = 2;
    self.terrain_t_map = rhi.Texture.init(self.ctx.args.disable_bindless) catch null;
    self.terrain_t_map.?.texture_unit = 3;

    const disable_bindless = rhi.Texture.disableBindless(self.ctx.args.disable_bindless);
    const frag_bindings = [_]usize{2};
    const tes_bindings = [_]usize{3};
    const terrain_vert = Compiler.runWithBytes(self.allocator, @embedFile("lod_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_vert);
    var terrain_frag = Compiler.runWithBytes(self.allocator, @embedFile("lod_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_frag);
    terrain_frag = if (!disable_bindless) terrain_frag else rhi.Shader.disableBindless(
        terrain_frag,
        frag_bindings[0..],
    ) catch @panic("bindless");
    const terrain_tcs = Compiler.runWithBytes(self.allocator, @embedFile("lod_tcs.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_tcs);
    var terrain_tes = Compiler.runWithBytes(self.allocator, @embedFile("lod_tes.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(terrain_tes);
    terrain_tes = if (!disable_bindless) terrain_tes else rhi.Shader.disableBindless(
        terrain_tes,
        tes_bindings[0..],
    ) catch @panic("bindless");

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
    if (self.terrain_t_map) |*t| {
        t.setup(self.ctx.textures_loader.loadAsset("cgpoc\\tessellation\\square_moon_bump.jpg") catch null, prog, "f_height_samp") catch {
            self.terrain_t_map = null;
        };
    }
    {
        var m = math.matrix.identity();
        m = math.matrix.transformMatrix(m, math.matrix.translate(0, 0, 0));
        m = math.matrix.transformMatrix(m, math.matrix.uniformScale(100));
        var u = rhi.Uniform.init(prog, "f_terrain_m") catch @panic("uniform");
        u.setUniformMatrix(m);
        self.terrain_u = u;
    }
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
const Compiler = @import("../../../../../fssc/Compiler.zig");
const LodTessellatorUI = @import("LodTessellatorUI.zig");
