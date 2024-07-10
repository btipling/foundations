program: u32,
objects: [1]object.object = undefined,
ui_state: sphere_ui,

const Sphere = @This();

const vertex_shader: []const u8 = @embedFile("sphere_vertex.glsl");
const frag_shader: []const u8 = @embedFile("sphere_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .shape,
        .name = "Sphere",
    };
}

pub fn init(allocator: std.mem.Allocator) *Sphere {
    const p = allocator.create(Sphere) catch @panic("OOM");

    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    const sphere: object.object = .{
        .sphere = object.sphere.init(
            program,
            .{ 1, 1, 1, 1 },
        ),
    };
    p.* = .{
        .program = program,
        .objects = .{
            sphere,
        },
        .ui_state = .{
            .wireframe = false,
            .rotation_time = 5.0,
        },
    };

    return p;
}

pub fn deinit(self: *Sphere, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn draw(self: *Sphere, frame_time: f64) void {
    const ft: f32 = @floatCast(frame_time);
    const rot = @mod(ft, self.ui_state.rotation_time) / self.ui_state.rotation_time;
    const angle_radiants: f32 = @as(f32, @floatCast(rot)) * std.math.pi * 2;
    self.objects[0].sphere.mesh.wire_mesh = self.ui_state.wireframe;
    rhi.drawObjects(self.objects[0..]);
    const m = math.matrix.leftHandedXUpToNDC();
    rhi.setUniformMatrix(self.program, "f_transform", m);
    rhi.setUniformMatrix(self.program, "f_color_transform", math.matrix.rotationY(angle_radiants));
    self.ui_state.draw();
}

const std = @import("std");
const ui = @import("../../ui/ui.zig");
const rhi = @import("../../rhi/rhi.zig");
const sphere_ui = @import("sphere_ui.zig");
const object = @import("../../object/object.zig");
const math = @import("../../math/math.zig");
