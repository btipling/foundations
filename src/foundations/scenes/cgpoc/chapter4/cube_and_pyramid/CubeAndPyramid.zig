allocator: std.mem.Allocator,
pyramid: object.object = .{ .norender = .{} },
parallelepiped: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*CubeAndPyramid, physics.Integrator(physics.SmoothDeceleration)),

const CubeAndPyramid = @This();

const num_cubes = 1;

const pyramid_vertex_shader: []const u8 = @embedFile("pyramid_vertex.glsl");
const cube_vertex_shader: []const u8 = @embedFile("cube_vertex.glsl");
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
    pd.renderPyramid();
    pd.renderParallepiped();
    return pd;
}

pub fn deinit(self: *CubeAndPyramid, allocator: std.mem.Allocator) void {
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn draw(self: *CubeAndPyramid, dt: f64) void {
    self.view_camera.update(dt);
    {
        const objects: [2]object.object = .{
            self.pyramid,
            self.parallelepiped,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn updateCamera(_: *CubeAndPyramid) void {}

pub fn updatePyramidTransform(_: *CubeAndPyramid, prog: u32) void {
    const m = math.matrix.identity();
    rhi.setUniformMatrix(prog, "f_transform", m);
}

pub fn renderPyramid(self: *CubeAndPyramid) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, pyramid_vertex_shader, frag_shader);
    var cm = math.matrix.identity();
    cm = math.matrix.transformMatrix(cm, math.matrix.translate(5, 4, 3));
    cm = math.matrix.transformMatrix(cm, math.matrix.scale(1.5, 1, 1));
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
}

pub fn updateParallepipedTransform(_: *CubeAndPyramid, prog: u32) void {
    const m = math.matrix.identity();
    rhi.setUniformMatrix(prog, "f_transform", m);
}

pub fn renderParallepiped(self: *CubeAndPyramid) void {
    const prog = rhi.createProgram();
    rhi.attachShaders(prog, cube_vertex_shader, frag_shader);
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(0, 0, -1));
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(2));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 1, 1 },
        };
        i_datas[0] = i_data;
    }
    const parallelepiped: object.object = .{
        .parallelepiped = object.Parallelepiped.init(
            prog,
            i_datas[0..],
            false,
        ),
    };
    self.updateParallepipedTransform(prog);
    self.view_camera.addProgram(prog, "f_mvp");
    self.parallelepiped = parallelepiped;
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const object = @import("../../../../object/object.zig");
const config = @import("../../../../config/config.zig");
const physics = @import("../../../../physics/physics.zig");
