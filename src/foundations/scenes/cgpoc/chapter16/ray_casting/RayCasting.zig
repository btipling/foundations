view_camera: *physics.camera.Camera(*RayCasting, physics.Integrator(physics.SmoothDeceleration)),
ctx: scenes.SceneContext,
allocator: std.mem.Allocator,
ui_state: RayCastingUI,

cross: scenery.debug.Cross = undefined,

ray_cast_buffer: SSBO,
ray_cast_prog: u32 = undefined,
ray_cast_tex: ?rhi.Texture = null,

scene_quad: object.object = .{ .norender = .{} },

const RayCasting = @This();

pub const SceneData = struct {
    sphere_radius: f32,
    sphere_position: [3]f32,
    sphere_color: [4]f32,
    box_position: [4]f32,
    box_dims: [4]f32,
    box_color: [4]f32,
    box_rotation: [4]f32,
};

pub const binding_point: rhi.storage_buffer.storage_binding_point = .{ .ssbo = 3 };
const SSBO = rhi.storage_buffer.Buffer(SceneData, binding_point, c.GL_DYNAMIC_COPY);

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
        .{ 0, -2, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    const cd: SceneData = .{
        .sphere_radius = 2.5,
        .sphere_position = .{ 1, 0, -3 },
        .sphere_color = .{ 0, 0, 1, 1 },
        .box_position = .{ -1.5, -1.5, 0, 0 },
        .box_dims = .{ 1, 1, 1, 0 },
        .box_color = .{ 1, 0, 0, 0 },
        .box_rotation = .{ 0, 0, 0, 0 },
    };

    var rc_buf = SSBO.init(cd, "scene_data");
    errdefer rc_buf.deinit();
    const ui_state: RayCastingUI = .{};

    rc.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .ctx = ctx,
        .view_camera = cam,
        .ray_cast_buffer = rc_buf,
    };

    rc.renderDebugCross();
    errdefer rc.deleteCross();

    rc.initScene();
    errdefer c.glDeleteProgram(rc.ray_cast_prog);

    rc.renderQuad();
    errdefer rhi.deleteObject(rc.scene_quad);

    return rc;
}

pub fn deinit(self: *RayCasting, allocator: std.mem.Allocator) void {
    self.ray_cast_buffer.deinit();
    c.glDeleteProgram(self.ray_cast_prog);
    rhi.deleteObject(self.scene_quad);
    self.deleteCross();
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn updateCamera(_: *RayCasting) void {}

pub fn draw(self: *RayCasting, dt: f64) void {
    self.rayCastScene();
    self.view_camera.update(dt);
    {
        rhi.drawObject(self.scene_quad);
    }
    self.cross.draw(dt);
    self.ui_state.draw();
}

fn rayCastScene(self: *RayCasting) void {
    c.glUseProgram(self.ray_cast_prog);
    c.glDispatchCompute(6, 1, 1);
    c.glMemoryBarrier(c.GL_ALL_BARRIER_BITS);
}

fn initScene(self: *RayCasting) void {
    const prog = rhi.createProgram("ray_cast_program");
    const comp = Compiler.runWithBytes(self.allocator, @embedFile("raycast_compute.glsl")) catch @panic("shader compiler");
    defer self.allocator.free(comp);

    const shaders = [_]rhi.Shader.ShaderData{
        .{ .source = comp, .shader_type = c.GL_COMPUTE_SHADER },
    };
    const s: rhi.Shader = .{
        .program = prog,
    };
    s.attachAndLinkAll(self.allocator, shaders[0..], "floor");

    self.ray_cast_prog = prog;
}

fn deleteCross(self: *RayCasting) void {
    self.cross.deinit(self.allocator);
}

fn renderDebugCross(self: *RayCasting) void {
    self.cross = scenery.debug.Cross.init(
        self.allocator,
        math.matrix.translate(0.0, 0.0, 0.0),
        5,
    );
}

fn renderQuad(self: *RayCasting) void {
    const prog = rhi.createProgram("scene_quad");
    const frag_bindings = [_]usize{ 4, 2, 3 };
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
    s.attachAndLinkAll(self.allocator, shaders[0..], "scene_quad");
    var m = math.matrix.identity();
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
    var grid_obj: object.object = .{ .quad = object.Quad.initPlane(prog, i_datas[0..], "scene_quad") };
    grid_obj.quad.mesh.linear_colorspace = false;
    self.scene_quad = grid_obj;
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
