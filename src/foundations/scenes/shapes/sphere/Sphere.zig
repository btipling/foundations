program: u32,
objects: [1]object.object = undefined,
ui_state: sphere_ui,
ctx: scenes.SceneContext,
aspect_ratio: f32,

const Sphere = @This();

const vertex_shader: []const u8 = @embedFile("sphere_vertex.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .shape,
        .name = "Sphere",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *Sphere {
    const p = allocator.create(Sphere) catch @panic("OOM");
    errdefer allocator.destroy(p);

    const prog = rhi.createProgram("sphere");
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .normal,
        };
        s.attach(allocator, rhi.Shader.single_vertex(vertex_shader)[0..], "sphere");
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        const m = math.matrix.identity();
        i_datas[0] = .{
            .t_column0 = m.columns[0],
            .t_column1 = m.columns[1],
            .t_column2 = m.columns[2],
            .t_column3 = m.columns[3],
            .color = .{ 1, 0, 0, 0.1 },
        };
    }
    const sphere: object.object = .{
        .sphere = object.Sphere.init(
            prog,
            i_datas[0..],
            "sphere",
        ),
    };
    p.* = .{
        .program = prog,
        .objects = .{
            sphere,
        },
        .ui_state = .{
            .wireframe = false,
            .rotation_time = 5.0,
        },
        .ctx = ctx,
        .aspect_ratio = @as(f32, @floatFromInt(ctx.cfg.width)) / @as(f32, @floatFromInt(ctx.cfg.height)),
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
    var m = math.matrix.orthographicProjection(0, 9, 0, 6, self.ctx.cfg.near, self.ctx.cfg.far);
    m = math.matrix.transformMatrix(m, math.matrix.leftHandedXUpToNDC());
    m = math.matrix.transformMatrix(m, math.matrix.translate(0, 3.5, 0));
    m = math.matrix.transformMatrix(m, math.matrix.uniformScale(3));
    rhi.setUniformMatrix(self.program, "f_transform", m);
    rhi.setUniformMatrix(self.program, "f_color_transform", math.matrix.rotationY(angle_radiants));
    self.ui_state.draw();
}

const std = @import("std");
const ui = @import("../../../ui/ui.zig");
const rhi = @import("../../../rhi/rhi.zig");
const sphere_ui = @import("SphereUI.zig");
const object = @import("../../../object/object.zig");
const math = @import("../../../math/math.zig");
const scenes = @import("../../scenes.zig");
