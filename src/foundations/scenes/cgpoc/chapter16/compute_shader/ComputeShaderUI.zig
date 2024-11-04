results: [6]f32 = .{ 0, 0, 0, 0, 0, 0 },

const ComputeShaderUI = @This();

pub fn draw(self: *ComputeShaderUI) void {
    const vp: *c.ImGuiViewport = c.igGetMainViewport();
    const pos = c.ImVec2_ImVec2_Float(vp.WorkPos.x + 50, vp.WorkPos.y + 50);
    c.igSetNextWindowPos(pos.*, c.ImGuiCond_FirstUseEver, c.ImVec2_ImVec2_Float(0, 0).*);
    const size = c.ImVec2_ImVec2_Float(550, 680);
    c.igSetNextWindowSize(size.*, c.ImGuiCond_FirstUseEver);
    _ = c.igBegin("Compute Shader", null, 0);

    var buf: [500]u8 = undefined;
    for (0..6) |i| {
        const result_text = std.fmt.bufPrintZ(&buf, "out[{d}]: {d:.3}", .{ i, self.results[i] }) catch @panic("bufsize too small");
        _ = c.igText(result_text);
    }
    c.igEnd();
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const math = @import("../../../../math/math.zig");
