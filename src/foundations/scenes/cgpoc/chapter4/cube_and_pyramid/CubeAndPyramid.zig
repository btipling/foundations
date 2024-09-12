allocator: std.mem.Allocator,
pyramid: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*CubeAndPyramid, physics.Integrator(physics.SmoothDeceleration)),
time_uinform: rhi.Uniform = undefined,

const CubeAndPyramid = @This();

const num_cubes = 1;

const transforms: []const u8 = @embedFile("../../../../shaders/transforms.glsl");
const vertex_main: []const u8 = @embedFile("cube_and_pyramid_vertex_main.glsl");
const vertex_header: []const u8 = @embedFile("cube_and_pyramid_vertex_header.glsl");
const frag_shader: []const u8 = @embedFile("cube_and_pyramid_frag.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Cube And Pyramid",
    };
}

pub fn init(allocator: std.mem.Allocator, cfg: *config) *CubeAndPyramid {
    const pd = allocator.create(CubeAndPyramid) catch @panic("OOM");

    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*CubeAndPyramid, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        cfg,
        pd,
        integrator,
        .{ 3, -8, 0 },
        0,
    );
    errdefer cam.deinit(allocator);

    pd.* = .{
        .allocator = allocator,
        .view_camera = cam,
    };
    pd.renderParallepiped();
    return pd;
}

pub fn deinit(self: *CubeAndPyramid, allocator: std.mem.Allocator) void {
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *CubeAndPyramid, dt: f64) void {
    self.time_uinform.setUniform1f(@floatCast(dt));
    self.view_camera.update(dt);
    {
        const objects: [1]object.object = .{
            self.pyramid,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn updateCamera(_: *CubeAndPyramid) void {}

pub fn updatePyramidTransform(_: *CubeAndPyramid, prog: u32) void {
    const m = math.matrix.identity();
    rhi.setUniformMatrix(prog, "f_cube_transform", m);
}

pub fn renderParallepiped(self: *CubeAndPyramid) void {
    const prog = rhi.createProgram();
    const vertex_shader = std.mem.concat(self.allocator, u8, &[_][]const u8{
        vertex_header,
        transforms,
        vertex_main,
    }) catch @panic("OOM");
    defer self.allocator.free(vertex_shader);
    rhi.attachShaders(prog, vertex_shader, frag_shader);
    var cm = math.matrix.identity();
    cm = math.matrix.transformMatrix(cm, math.matrix.translate(0, -1, -1));
    cm = math.matrix.transformMatrix(cm, math.matrix.scale(2, 1, 1));
    const i_data: rhi.instanceData = .{
        .t_column0 = cm.columns[0],
        .t_column1 = cm.columns[1],
        .t_column2 = cm.columns[2],
        .t_column3 = cm.columns[3],
        .color = .{ 1, 0, 1, 1 },
    };
    var i_datas: [num_cubes]rhi.instanceData = undefined;
    for (0..num_cubes) |i| {
        i_datas[i] = i_data;
    }
    const pyramid: object.object = .{
        .pyramid = object.Pyramid.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.updatePyramidTransform(prog);
    self.view_camera.addProgram(prog, "f_mvp");
    self.pyramid = pyramid;
    self.time_uinform = rhi.Uniform.init(prog, "f_tf");
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const object = @import("../../../../object/object.zig");
const config = @import("../../../../config/config.zig");
const physics = @import("../../../../physics/physics.zig");
