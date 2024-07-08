objects: [100]object.object = undefined,
num_objects: usize = 0,
ui_state: line_ui,

const Line = @This();

const vertex_shader: []const u8 = @embedFile("line_vertex.glsl");
const frag_shader: []const u8 = @embedFile("line_frag.glsl");

pub fn init(allocator: std.mem.Allocator) *Line {
    const line = allocator.create(Line) catch @panic("OOM");

    line.* = .{
        .ui_state = .{},
    };

    return line;
}

pub fn deinit(self: *Line, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *Line, _: f64) void {
    if (ui.input.get()) |input| {
        const button = input.mouse_button orelse return;
        const action = input.mouse_action orelse return;
        const x = input.mouse_x orelse return;
        const z = input.mouse_z orelse return;
        if (button != c.GLFW_MOUSE_BUTTON_1) return;
        if (action != c.GLFW_PRESS) return;
        self.addPoint(x, z);
    }
    if (self.num_objects > 0) rhi.drawObjects(self.objects[0..self.num_objects]);
    self.ui_state.draw();
}

fn addPoint(self: *Line, x: f32, z: f32) void {
    if (self.num_objects == self.objects.len) return;
    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    const circle: object.object = .{
        .circle = object.circle.init(
            program,
            .{ 1, 1, 1, 1 },
        ),
    };
    var m = math.matrix.leftHandedXUpToNDC();
    m = math.matrix.transformMatrix(m, math.matrix.translate(x, 0, z));
    m = math.matrix.transformMatrix(m, math.matrix.scale(0.01, 0.01, 0.01));
    rhi.setUniformMatrix(program, "f_transform", m);
    self.objects[self.num_objects] = circle;
    self.num_objects += 1;
}

const std = @import("std");
const c = @import("../../c.zig").c;
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const line_ui = @import("line_ui.zig");
const object = @import("../../object/object.zig");
const math = @import("../../math/math.zig");
