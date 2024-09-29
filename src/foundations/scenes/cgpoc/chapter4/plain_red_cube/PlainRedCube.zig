allocator: std.mem.Allocator,
grid: *scenery.Grid = undefined,
parallelepiped: object.object = .{ .norender = .{} },
view_camera: *physics.camera.Camera(*PlainRedCube, physics.Integrator(physics.SmoothDeceleration)),

const PlainRedCube = @This();

const vertex_shader: []const u8 = @embedFile("plain_red_cube_vertex.glsl");

pub fn navType() ui.ui_state.scene_nav_info {
    return .{
        .nav_type = .cgpoc,
        .name = "Plain Red Cube",
    };
}

pub fn init(allocator: std.mem.Allocator, ctx: scenes.SceneContext) *PlainRedCube {
    const pd = allocator.create(PlainRedCube) catch @panic("OOM");
    errdefer allocator.destroy(pd);
    const integrator = physics.Integrator(physics.SmoothDeceleration).init(.{});
    const cam = physics.camera.Camera(*PlainRedCube, physics.Integrator(physics.SmoothDeceleration)).init(
        allocator,
        ctx.cfg,
        pd,
        integrator,
        .{ 3, -8, 0 },
        0,
    );
    errdefer cam.deinit(allocator);
    const grid = scenery.Grid.init(allocator);
    errdefer grid.deinit();

    pd.* = .{
        .allocator = allocator,
        .view_camera = cam,
        .grid = grid,
    };
    pd.renderParallepiped();
    errdefer pd.deleteCube();

    return pd;
}

pub fn deinit(self: *PlainRedCube, allocator: std.mem.Allocator) void {
    self.deleteCube();
    self.grid.deinit();
    self.grid = undefined;
    self.view_camera.deinit(allocator);
    self.view_camera = undefined;
    allocator.destroy(self);
}

pub fn deleteCube(self: *PlainRedCube) void {
    const objects: [1]object.object = .{
        self.parallelepiped,
    };
    rhi.deleteObjects(objects[0..]);
}

pub fn draw(self: *PlainRedCube, dt: f64) void {
    self.view_camera.update(dt);
    self.grid.draw(dt);
    {
        const objects: [1]object.object = .{
            self.parallelepiped,
        };
        rhi.drawObjects(objects[0..]);
    }
}

pub fn updateCamera(_: *PlainRedCube) void {}

pub fn updateParallepipedTransform(_: *PlainRedCube, prog: u32) void {
    const m = math.matrix.identity();
    rhi.setUniformMatrix(prog, "f_cube_transform", m);
}

pub fn renderParallepiped(self: *PlainRedCube) void {
    const prog = rhi.createProgram();
    {
        var s: rhi.Shader = .{
            .program = prog,
            .instance_data = true,
            .fragment_shader = .color,
        };
        s.attach(self.allocator, rhi.Shader.single_vertex(vertex_shader)[0..]);
    }
    var i_datas: [1]rhi.instanceData = undefined;
    {
        var cm = math.matrix.identity();
        cm = math.matrix.transformMatrix(cm, math.matrix.translate(0, -1, -1));
        cm = math.matrix.transformMatrix(cm, math.matrix.uniformScale(2));
        const i_data: rhi.instanceData = .{
            .t_column0 = cm.columns[0],
            .t_column1 = cm.columns[1],
            .t_column2 = cm.columns[2],
            .t_column3 = cm.columns[3],
            .color = .{ 1, 0, 0, 1 },
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
    self.parallelepiped = parallelepiped;
}

const std = @import("std");
const c = @import("../../../../c.zig").c;
const ui = @import("../../../../ui/ui.zig");
const rhi = @import("../../../../rhi/rhi.zig");
const math = @import("../../../../math/math.zig");
const object = @import("../../../../object/object.zig");
const scenes = @import("../../../scenes.zig");
const physics = @import("../../../../physics/physics.zig");
const scenery = @import("../../../../scenery/scenery.zig");
