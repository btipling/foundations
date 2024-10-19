view_camera: *physics.camera.Camera(*BasicTessellator, physics.Integrator(physics.SmoothDeceleration)),
program: u32,
vao: u32,
buffer: u32,
count: usize,
ctx: scenes.SceneContext,
cross: scenery.debug.Cross = undefined,
allocator: std.mem.Allocator = undefined,

x: f32 = 0,
inc: f32 = 0.01,

const BasicTessellator = @This();

const vertex_shader: []const u8 = @embedFile("vertex.glsl");

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
    const prog = rhi.createProgram();
    const vao = rhi.createVAO();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = false,
            .fragment_shader = .color,
        };
        s.attach(allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }

    bt.* = .{
        .view_camera = cam,
        .program = prog,
        .vao = vao,
        .buffer = 0,
        .count = 1,
        .ctx = ctx,
        .allocator = allocator,
    };

    

    bt.renderDebugCross();
    errdefer bt.deleteDebugCross();
    
    return bt;
}

pub fn deinit(self: *BasicTessellator, allocator: std.mem.Allocator) void {
    self.deleteCross();
    rhi.deletePrimitive(self.program, self.vao, self.buffer);
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *BasicTessellator) void {}

pub fn draw(self: *BasicTessellator, dt: f64) void {
    self.view_camera.update(dt);
    self.x += self.inc;
    if (self.x >= 1) {
        self.inc = -self.inc;
    }
    if (self.x < -1) {
        self.inc = -self.inc;
    }
    rhi.setUniform1f(self.program, "f_offset", self.x);
    rhi.drawPoints(self.program, self.vao, self.count);
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

const std = @import("std");
const rhi = @import("../../../../rhi/rhi.zig");
const ui = @import("../../../../ui/ui.zig");
const scenes = @import("../../../scenes.zig");
const math = @import("../../../../math/math.zig");
const physics = @import("../../../../physics/physics.zig");
const scenery = @import("../../../../scenery/scenery.zig");