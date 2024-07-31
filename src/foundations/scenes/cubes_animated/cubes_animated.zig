program: u32,
objects: [1]object.object = undefined,
ui_state: ca_ui,

const kf0: math.rotation.Quat = math.rotation.axisAngleToQuat(
    math.rotation.degreesToRadians(25),
    @as(math.vector.vec3, .{ 0, 1, 1 }),
);
const kf1: math.rotation.Quat = math.rotation.axisAngleToQuat(
    math.rotation.degreesToRadians(100.0),
    @as(math.vector.vec3, .{ 0, 1, 1 }),
);
const kf2: math.rotation.Quat = math.rotation.axisAngleToQuat(
    math.rotation.degreesToRadians(175.0),
    @as(math.vector.vec3, .{ 0, 1, 1 }),
);
const kf3: math.rotation.Quat = math.rotation.axisAngleToQuat(
    math.rotation.degreesToRadians(220.0),
    @as(math.vector.vec3, .{ 0, 1, 1 }),
);
const kf4: math.rotation.Quat = math.rotation.axisAngleToQuat(
    math.rotation.degreesToRadians(280.0),
    @as(math.vector.vec3, .{ 0, 1, 1 }),
);
const kf5: math.rotation.Quat = math.rotation.axisAngleToQuat(
    math.rotation.degreesToRadians(80.0),
    @as(math.vector.vec3, .{ 1, 0, 1 }),
);
const kf6: math.rotation.Quat = math.rotation.axisAngleToQuat(
    math.rotation.degreesToRadians(30.0),
    @as(math.vector.vec3, .{ 1, 0, 1 }),
);

const key_frames = [_]math.rotation.Quat{ kf0, kf1, kf2, kf3, kf4, kf5, kf6, kf0 };

const LinearColorSpace = @This();

const vertex_shader: []const u8 = @embedFile("ca_vertex.glsl");
const frag_shader: []const u8 = @embedFile("ca_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .shape,
        .name = "Cube",
    };
}

pub fn init(allocator: std.mem.Allocator) *LinearColorSpace {
    const p = allocator.create(LinearColorSpace) catch @panic("OOM");

    const program = rhi.createProgram();
    rhi.attachShaders(program, vertex_shader, frag_shader);
    const cube: object.object = .{
        .cube = object.cube.init(
            program,
            object.cube.default_positions,
            .{ 1, 0, 1, 1 },
        ),
    };
    p.* = .{
        .program = program,
        .ui_state = ca_ui.init(),
    };
    p.objects[0] = cube;
    return p;
}

pub fn deinit(self: *LinearColorSpace, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

const animation_duration: f64 = @floatFromInt(key_frames.len - 1);

pub fn draw(self: *LinearColorSpace, frame_time: f64) void {
    var frame_times: [key_frames.len]f32 = undefined;
    comptime var i: usize = 0;
    inline while (i < key_frames.len) : (i += 1) {
        frame_times[i] = @floatFromInt(i);
    }

    const t: f32 = @as(f32, @floatCast(@mod(frame_time, animation_duration)));
    var m = math.matrix.perspectiveProjection(45.0, 1.0, 0.1, 500.0);
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
    const pinhole_distance: f32 = 0;
    rhi.setUniform1f(self.program, "f_pinhole", pinhole_distance);
    self.ui_state.draw();
}

const std = @import("std");
const rhi = @import("../../rhi/rhi.zig");
const object = @import("../../object/object.zig");
const math = @import("../../math/math.zig");
const ca_ui = @import("cubes_animated_ui.zig");
const ui = @import("../../ui/ui.zig");
