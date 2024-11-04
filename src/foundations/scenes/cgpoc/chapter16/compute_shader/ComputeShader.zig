ctx: scenes.SceneContext,
allocator: std.mem.Allocator,
ui_state: ComputeShaderUI,
compute_buffer: SSBO,

const ComputeShader = @This();

pub const ComputeData = struct {
    v1: [6]f32,
    v2: [6]f32,
    out: [6]f32,
};

pub const binding_point: rhi.storage_buffer.storage_binding_point = .{ .ssbo = 3 };
const SSBO = rhi.storage_buffer.Buffer(ComputeData, binding_point, c.GL_DYNAMIC_DRAW);

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Compute Shader",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *ComputeShader {
    const cs = allocator.create(ComputeShader) catch @panic("OOM");
    errdefer allocator.destroy(cs);

    const cd: ComputeData = .{
        .v1 = .{ 10, 12, 16, 18, 50, 17 },
        .v2 = .{ 30, 14, 80, 20, 51, 12 },
        .out = .{ 0, 0, 0, 0, 0, 0 },
    };
    var cd_buf = SSBO.init(cd, "compute_data");
    errdefer cd_buf.deinit();
    const ui_state: ComputeShaderUI = .{};
    cs.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .ctx = ctx,
        .compute_buffer = cd_buf,
    };

    return cs;
}

pub fn deinit(self: *ComputeShader, allocator: std.mem.Allocator) void {
    self.compute_buffer.deinit();
    allocator.destroy(self);
}

pub fn draw(self: *ComputeShader, _: f64) void {
    self.ui_state.draw();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const scenes = @import("../../../scenes.zig");
const ComputeShaderUI = @import("ComputeShaderUI.zig");
