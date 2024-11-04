ctx: scenes.SceneContext,
allocator: std.mem.Allocator,
ui_state: ComputeShaderUI,

const ComputeShader = @This();
pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Compute Shader",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *ComputeShader {
    const cs = allocator.create(ComputeShader) catch @panic("OOM");
    errdefer allocator.destroy(cs);

    const ui_state: ComputeShaderUI = .{};
    cs.* = .{
        .ui_state = ui_state,
        .allocator = allocator,
        .ctx = ctx,
    };

    return cs;
}

pub fn deinit(self: *ComputeShader, allocator: std.mem.Allocator) void {
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
