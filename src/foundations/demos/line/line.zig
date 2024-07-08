program: u32,
objects: [1]object.object = undefined,
ui_state: line_ui,

const Line = @This();

const vertex_shader: []const u8 = @embedFile("line_vertex.glsl");
const frag_shader: []const u8 = @embedFile("line_frag.glsl");

pub fn init(allocator: std.mem.Allocator) *Line {
    const p = allocator.create(Line) catch @panic("OOM");

    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    const circle: object.object = .{
        .circle = object.circle.init(
            program,
            .{ 1, 1, 1, 1 },
        ),
    };
    p.* = .{
        .program = program,
        .objects = .{
            circle,
        },
        .ui_state = .{},
    };

    return p;
}

pub fn deinit(self: *Line, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *Line, _: f64) void {
    if (ui.input.get()) |input| {
        if (input.mouse_action) |action| {
            std.debug.print("line mouse action: {d} mouse x: {any} mouse y: {any}\n", .{
                action,
                input.mouse_x,
                input.mouse_y,
            });
        }
    }
    rhi.drawObjects(self.objects[0..]);
    self.ui_state.draw();
}

const std = @import("std");
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const line_ui = @import("line_ui.zig");
const object = @import("../../object/object.zig");
const math = @import("../../math/math.zig");
