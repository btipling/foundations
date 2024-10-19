view_camera: *physics.camera.Camera(*BasicTessellator, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

grid_program: u32 = undefined,
grid_vao: u32 = undefined,
grid_m: math.matrix = math.matrix.identity(),
grid_u: rhi.Uniform = undefined,

surface_program: u32 = undefined,
surface_vao: u32 = undefined,
surface_m: math.matrix = math.matrix.identity(),
surface_u: rhi.Uniform = undefined,

const BasicTessellator = @This();

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Basic Tessellator",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *BasicTessellator {
    const bt = allocator.create(BasicTessellator) catch @panic("OOM");
    errdefer allocator.destroy(bt);

    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    var cam = physics.camera.Camera(*BasicTessellator, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        bt,
        integrator,
        .{ 2, -4, 2 },
        0,
    );
    errdefer cam.deinit(allocator);

    bt.* = .{
        .view_camera = cam,
        .ctx = ctx,
        .allocator = allocator,
    };

    bt.renderGrid();
    errdefer bt.deleteGrid();

    bt.renderSurface();
    errdefer bt.deleteSurface();

    bt.renderDebugCross();
    errdefer bt.deleteDebugCross();

    return bt;
}

pub fn deinit(self: *BasicTessellator, allocator: std.mem.Allocator) void {
    self.deleteCross();
    self.deleteGrid();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *BasicTessellator) void {}

pub fn draw(self: *BasicTessellator, dt: f64) void {
    self.view_camera.update(dt);
    {
        rhi.runTessalation(self.grid_program, 1);
    }
    {
        rhi.runTessalation(self.surface_program, 16);
    }
    self.cross.draw(dt);
}

pub fn deleteCross(self: *BasicTessellator) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *BasicTessellator) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, -0.025, -0.025),
        5,
    );
}

pub fn deleteGrid(self: *BasicTessellator) void {
    rhi.deletePrimitive(self.grid_program, self.grid_vao, 0);
}

pub fn renderGrid(self: *BasicTessellator) void {
    const prog = rhi.createProgram();
    const vao = rhi.createVAO();

    const grid_vert = Compiler.runWithBytes(self.allocator, @embedFile("grid_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(grid_vert);
    const grid_frag = Compiler.runWithBytes(self.allocator, @embedFile("grid_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(grid_frag);
    const grid_tcs = Compiler.runWithBytes(self.allocator, @embedFile("grid_tcs.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(grid_tcs);
    const grid_tes = Compiler.runWithBytes(self.allocator, @embedFile("grid_tes.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(grid_tes);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = grid_vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = grid_frag, .shader_type = c.GL_FRAGMENT_SHADER },
        .{ .source = grid_tcs, .shader_type = c.GL_TESS_CONTROL_SHADER },
        .{ .source = grid_tes, .shader_type = c.GL_TESS_EVALUATION_SHADER },
    };

    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translate(0, 0, 5));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(10));
    var u = rhi.Uniform.init(prog, "f_grid_m") catch @panic("uniform");
    u.setUniformMatrix(m);
    self.grid_u = u;
    self.grid_program = prog;
    self.grid_vao = vao;
}

pub fn deleteSurface(self: *BasicTessellator) void {
    rhi.deletePrimitive(self.grid_program, self.grid_vao, 0);
}

pub fn renderSurface(self: *BasicTessellator) void {
    const prog = rhi.createProgram();
    const vao = rhi.createVAO();

    const surface_vert = Compiler.runWithBytes(self.allocator, @embedFile("surface_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(surface_vert);
    const surface_frag = Compiler.runWithBytes(self.allocator, @embedFile("surface_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(surface_frag);
    const surface_tcs = Compiler.runWithBytes(self.allocator, @embedFile("surface_tcs.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(surface_tcs);
    const surface_tes = Compiler.runWithBytes(self.allocator, @embedFile("surface_tes.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(surface_tes);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = surface_vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = surface_frag, .shader_type = c.GL_FRAGMENT_SHADER },
        .{ .source = surface_tcs, .shader_type = c.GL_TESS_CONTROL_SHADER },
        .{ .source = surface_tes, .shader_type = c.GL_TESS_EVALUATION_SHADER },
    };

    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);
    var m = math.matrix.identity();
    m = math.matrix.transformMatrix(m, math.matrix.translate(0, 0, -15));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(10));
    var u = rhi.Uniform.init(prog, "f_grid_m") catch @panic("uniform");
    u.setUniformMatrix(m);
    self.surface_u = u;
    self.surface_program = prog;
    self.surface_vao = vao;
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
