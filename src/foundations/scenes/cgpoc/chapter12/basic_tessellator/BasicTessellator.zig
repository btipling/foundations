view_camera: *physics.camera.Camera(*BasicTessellator, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

point_program: u32 = undefined,
point_vao: u32 = undefined,
point_x: f32 = 0,
point_inc: f32 = 0.01,

tess_program: u32 = undefined,
tess_vao: u32 = undefined,

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

    bt.renderPoint();
    errdefer bt.deletePoint();

    bt.renderDebugCross();
    errdefer bt.deleteDebugCross();

    return bt;
}

pub fn deinit(self: *BasicTessellator, allocator: std.mem.Allocator) void {
    self.deleteCross();
    self.deletePoint();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *BasicTessellator) void {}

pub fn draw(self: *BasicTessellator, dt: f64) void {
    self.view_camera.update(dt);
    {
        self.point_x += self.point_inc;
        if (self.point_x >= 1) {
            self.point_inc = -self.point_inc;
        }
        if (self.point_x < -1) {
            self.point_inc = -self.point_inc;
        }
        rhi.setUniform1f(self.point_program, "f_offset", self.point_x);
        rhi.drawPoints(self.point_program, self.point_vao, 1);
    }
    self.cross.draw(dt);
}

pub fn deleteCross(self: *BasicTessellator) void {
    self.cross.deinit(self.allocator);
}

pub fn renderDebugCross(self: *BasicTessellator) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0, 0, 0),
        5,
    );
}

pub fn deletePoint(self: *BasicTessellator) void {
    rhi.deletePrimitive(self.point_program, self.point_vao, 0);
}

pub fn renderPoint(self: *BasicTessellator) void {
    const prog = rhi.createProgram();
    const vao = rhi.createVAO();

    const point_vert = Compiler.runWithBytes(self.allocator, @embedFile("point_vert.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(point_vert);
    const point_frag = Compiler.runWithBytes(self.allocator, @embedFile("point_frag.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(point_frag);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = point_vert, .shader_type = c.GL_VERTEX_SHADER },
        .{ .source = point_frag, .shader_type = c.GL_FRAGMENT_SHADER },
    };

    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..]);
    self.point_program = prog;
    self.point_vao = vao;
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
