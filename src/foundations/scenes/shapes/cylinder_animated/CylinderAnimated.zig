program: u32,
objects: [1]object.object = undefined,
ui_state: CylinderAnimatedUI,
ctx: scenes.SceneContext,
aspect_ratio: f32,

const kf0: math.rotation.Quat = math.rotation.axisAngleToQuat(.{
    .angle = math.rotation.degreesToRadians(25),
    .axis = @as(math.vector.vec3, .{ 0, 1, 1 }),
});
const kf1: math.rotation.Quat = math.rotation.axisAngleToQuat(.{
    .angle = math.rotation.degreesToRadians(100.0),
    .axis = @as(math.vector.vec3, .{ 0, 1, 1 }),
});
const kf2: math.rotation.Quat = math.rotation.axisAngleToQuat(.{
    .angle = math.rotation.degreesToRadians(175.0),
    .axis = @as(math.vector.vec3, .{ 0, 1, 1 }),
});
const kf3: math.rotation.Quat = math.rotation.axisAngleToQuat(.{
    .angle = math.rotation.degreesToRadians(220.0),
    .axis = @as(math.vector.vec3, .{ 0, 1, 1 }),
});
const kf4: math.rotation.Quat = math.rotation.axisAngleToQuat(.{
    .angle = math.rotation.degreesToRadians(280.0),
    .axis = @as(math.vector.vec3, .{ 0, 1, 1 }),
});
const kf5: math.rotation.Quat = math.rotation.axisAngleToQuat(.{
    .angle = math.rotation.degreesToRadians(80.0),
    .axis = @as(math.vector.vec3, .{ 1, 0, 1 }),
});
const kf6: math.rotation.Quat = math.rotation.axisAngleToQuat(.{
    .angle = math.rotation.degreesToRadians(30.0),
    .axis = @as(math.vector.vec3, .{ 1, 0, 1 }),
});

const key_frames = [_]math.rotation.Quat{ kf0, kf1, kf2, kf3, kf4, kf5, kf6, kf0 };

const CylinderAnimated = @This();

const vertex_shader: []const u8 = @embedFile("ca_vertex.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .shape,
        .name = "Cylinder",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *CylinderAnimated {
    const p = allocator.create(CylinderAnimated) catch @panic("OOM");

    const prog = rhi.createProgram("cylinder_animated");
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .normal,
        };
        s.attach(allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
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
    const cylinder: object.object = .{
        .cylinder = object.Cylinder.init(
            prog,
            i_datas[0..],
            "cylinder",
        ),
    };
    p.* = .{
        .program = prog,
        .ui_state = CylinderAnimatedUI.init(),
        .ctx = ctx,
        .aspect_ratio = @as(f32, @floatFromInt(ctx.cfg.width)) / @as(f32, @floatFromInt(ctx.cfg.height)),
    };
    p.objects[0] = cylinder;
    return p;
}

pub fn deinit(self: *CylinderAnimated, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

const animation_duration: f64 = @floatFromInt(key_frames.len - 1);

pub fn draw(self: *CylinderAnimated, frame_time: f64) void {
    var frame_times: [key_frames.len]f32 = undefined;
    comptime var i: usize = 0;
    inline while (i < key_frames.len) : (i += 1) {
        frame_times[i] = @floatFromInt(i);
    }

    const t: f32 = @as(f32, @floatCast(@mod(frame_time, animation_duration)));
    var m = math.matrix.perspectiveProjection(self.ctx.cfg.fovy, self.aspect_ratio, self.ctx.cfg.near, self.ctx.cfg.far);
    if (self.ui_state.use_lh_x_up == 1) {
        m = math.matrix.transformMatrix(m, math.matrix.leftHandedXUpToNDC());
    }
    m = math.matrix.transformMatrix(m, math.matrix.translate(
        self.ui_state.x_translate,
        self.ui_state.y_translate,
        self.ui_state.z_translate,
    ));
    if (!self.ui_state.animate) {
        m = math.matrix.transformMatrix(m, math.matrix.rotationX(self.ui_state.x_rot));
        m = math.matrix.transformMatrix(m, math.matrix.rotationY(self.ui_state.y_rot));
        m = math.matrix.transformMatrix(m, math.matrix.rotationZ(self.ui_state.z_rot));
    } else if (self.ui_state.use_slerp == 1) {
        const orientation = math.interpolation.piecewiseSlerp(key_frames[0..], frame_times[0..], t);
        m = math.matrix.transformMatrix(m, math.matrix.normalizedQuaternionToMatrix(orientation));
    } else {
        const orientation = math.interpolation.piecewiseLerp(key_frames[0..], frame_times[0..], t);
        m = math.matrix.transformMatrix(m, math.matrix.normalizedQuaternionToMatrix(orientation));
    }
    m = math.matrix.transformMatrix(m, math.matrix.scale(
        self.ui_state.scale,
        self.ui_state.scale,
        self.ui_state.scale,
    ));

    rhi.drawObjects(self.objects[0..]);
    rhi.setUniformMatrix(self.program, "f_transform", m);
    self.ui_state.draw();
}

const std = @import("std");
const rhi = @import("../../../rhi/rhi.zig");
const object = @import("../../../object/object.zig");
const math = @import("../../../math/math.zig");
const CylinderAnimatedUI = @import("CylinderAnimatedUI.zig");
const ui = @import("../../../ui/ui.zig");
const scenes = @import("../../scenes.zig");
