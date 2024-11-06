ctx: scenes.SceneContext,
allocator: std.mem.Allocator,
ui_state: RayCastingUI,
ray_cast_buffer: SSBO,
ray_cast_prog: u32 = undefined,

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
        .ray_cast_buffer = rc_buf,
    };

    rc.initScene();

    return rc;
}

pub fn deinit(self: *RayCasting, allocator: std.mem.Allocator) void {
    self.ray_cast_buffer.deinit();
    c.glDeleteProgram(self.ray_cast_prog);
    allocator.destroy(self);
}

pub fn draw(self: *RayCasting, _: f64) void {
    self.rayCastScene();
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

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const scenes = @import("../../../scenes.zig");
const Compiler = @import("../../../../../fssc/Compiler.zig");
const RayCastingUI = @import("RayCastingUI.zig");
